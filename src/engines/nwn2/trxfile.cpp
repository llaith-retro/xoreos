/* xoreos - A reimplementation of BioWare's Aurora engine
 *
 * xoreos is the legal property of its developers, whose names
 * can be found in the AUTHORS file distributed with this source
 * distribution.
 *
 * xoreos is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 3
 * of the License, or (at your option) any later version.
 *
 * xoreos is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with xoreos. If not, see <http://www.gnu.org/licenses/>.
 */

/** @file
 *  Loader for Neverwinter Nights 2 baked terrain files (TRX).
 */

#include <memory>

#include "src/common/error.h"
#include "src/common/readstream.h"
#include "src/common/encoding.h"
#include "src/common/ustring.h"
#include "src/common/strutil.h"

#include "src/aurora/resman.h"

#include "src/graphics/graphics.h"
#include "src/graphics/vertexbuffer.h"
#include "src/graphics/indexbuffer.h"

#include "src/graphics/aurora/geometryobject.h"

#include "src/engines/nwn2/trxfile.h"

namespace Engines {

namespace NWN2 {

TRXFile::TRXFile(const Common::UString &resRef) : _visible(false) {
	try {
		std::unique_ptr<Common::SeekableReadStream> trx(ResMan.getResource(resRef, Aurora::kFileTypeTRX));
		if (!trx)
			throw Common::Exception("No such TRX");

		load(*trx);

	} catch (Common::Exception &e) {
		e.add("Failed to load TRX \"%s\"", resRef.c_str());
		throw e;
	}
}

TRXFile::~TRXFile() {
	hide();
}

void TRXFile::show() {
	if (_visible)
		return;

	GfxMan.lockFrame();

	for (auto &terrain : _terrain)
		terrain->show();
	for (auto &water : _water)
		water->show();

	_visible = true;

	GfxMan.unlockFrame();
}

void TRXFile::hide() {
	if (!_visible)
		return;

	GfxMan.lockFrame();

	for (auto &water : _water)
		water->hide();
	for (auto &terrain : _terrain)
		terrain->hide();

	_visible = false;

	GfxMan.unlockFrame();
}

void TRXFile::load(Common::SeekableReadStream &trx) {
	uint32_t magic = trx.readUint32BE();
	if (magic != MKTAG('N', 'W', 'N', '2'))
		throw Common::Exception("Invalid magic %s", Common::debugTag(magic).c_str());

	uint16_t versionMajor = trx.readUint16LE();
	uint16_t versionMinor = trx.readUint16LE();
	if ((versionMajor != 2) || (versionMinor != 3))
		throw Common::Exception("Invalid version %d.%d", versionMajor, versionMinor);

	uint32_t packetCount = trx.readUint32LE();
	if ((trx.size() - trx.pos()) < (packetCount * 8))
		throw Common::Exception("TRX won't fit the packet packets");

	std::vector<Packet> packets;
	packets.resize(packetCount);

	loadDirectory(trx, packets);
	loadPackets(trx, packets);
}

void TRXFile::loadDirectory(Common::SeekableReadStream &trx, std::vector<Packet> &packets) {
	for (std::vector<Packet>::iterator p = packets.begin(); p != packets.end(); ++p) {
		p->type   = trx.readUint32BE();
		p->offset = trx.readUint32LE();

		if (p->offset >= trx.size())
			throw Common::Exception("Offset of 0x%08X packet too big (%d)", p->type, p->offset);
	}
}

void TRXFile::loadPackets(Common::SeekableReadStream &trx, std::vector<Packet> &packets) {
	for (std::vector<Packet>::iterator p = packets.begin(); p != packets.end(); ++p) {
		trx.seek(p->offset);

		uint32_t type = trx.readUint32BE();
		if (type != p->type)
			throw Common::Exception("Packet type mismatch (0x%08X vs 0x%08X)", type, p->type);

		p->size = trx.readUint32LE();
		if ((trx.size() - trx.pos()) < p->size)
			throw Common::Exception("Size of 0x%8X packet too big (%d)", p->type, p->size);

		loadPacket(trx, *p);
	}
}

void TRXFile::loadPacket(Common::SeekableReadStream &trx, Packet &packet) {
	if      (packet.type == MKTAG('T', 'R', 'W', 'H'))
		loadTRWH(trx, packet);
	else if (packet.type == MKTAG('T', 'R', 'R', 'N'))
		loadTRRN(trx, packet);
	else if (packet.type == MKTAG('W', 'A', 'T', 'R'))
		loadWATR(trx, packet);
	else if (packet.type == MKTAG('A', 'S', 'W', 'M'))
		loadASWM(trx, packet);
	else
		throw Common::Exception("Unknown packet type %s", Common::debugTag(packet.type).c_str());
}

void TRXFile::loadTRWH(Common::SeekableReadStream &trx, Packet &packet) {
	if (packet.size != 12)
		throw Common::Exception("Invalid TRWH size (%d)", packet.size);

	_width  = trx.readUint32LE();
	_height = trx.readUint32LE();

	// trx.readUint32LE(); // Unknown
}

void TRXFile::loadTRRN(Common::SeekableReadStream &trx, Packet &packet) {
	Common::SeekableSubReadStream ttrn(&trx, trx.pos(), trx.pos() + packet.size);

	Common::UString name = Common::readStringFixed(ttrn, Common::kEncodingASCII, 128);

	Common::UString textures[6];
	for (int i = 0; i < 6; i++)
		textures[i] = Common::readStringFixed(ttrn, Common::kEncodingASCII, 32);

	float textureColors[6][3];
	for (int i = 0; i < 6; i++)
		for (int j = 0; j < 3; j++)
			textureColors[i][j] = ttrn.readIEEEFloatLE();

	const uint32_t vCount = ttrn.readUint32LE();
	const uint32_t fCount = ttrn.readUint32LE();

	Graphics::VertexDecl vertexDecl;

	vertexDecl.push_back(Graphics::VertexAttrib(Graphics::VPOSITION, 3, GL_FLOAT));
	vertexDecl.push_back(Graphics::VertexAttrib(Graphics::VNORMAL  , 3, GL_FLOAT));
	vertexDecl.push_back(Graphics::VertexAttrib(Graphics::VCOLOR   , 4, GL_FLOAT));

	Graphics::VertexBuffer vBuf;
	vBuf.setVertexDeclInterleave(vCount, vertexDecl);

	float *v = reinterpret_cast<float *>(vBuf.getData());
	for (uint32_t i = 0; i < vCount; i++) {
		*v++ = ttrn.readIEEEFloatLE();
		*v++ = ttrn.readIEEEFloatLE();
		*v++ = ttrn.readIEEEFloatLE();

		*v++ = ttrn.readIEEEFloatLE();
		*v++ = ttrn.readIEEEFloatLE();
		*v++ = ttrn.readIEEEFloatLE();

		for (int j = 0; j < 3; j++) {
			int   vals = 1;
			float rgb  = ttrn.readByte() / 255.0f;

			for (int k = 0; k < 6; k++) {
				if (!textures[k].empty()) {
					rgb += textureColors[k][j];
					vals++;
				}
			}

			rgb /= vals;

			*v++ = rgb;
		}

		*v++ = ttrn.readByte() / 255.0f;

		ttrn.skip(16); // Some texture coordinates?
	}

	Graphics::IndexBuffer iBuf;
	iBuf.setSize(fCount * 3, sizeof(uint16_t), GL_UNSIGNED_SHORT);

	uint16_t *f = reinterpret_cast<uint16_t *>(iBuf.getData());
	for (uint32_t i = 0; i < fCount; i++) {
		*f++ = ttrn.readUint16LE();
		*f++ = ttrn.readUint16LE();
		*f++ = ttrn.readUint16LE();
	}

	/* TODO:
	 *   - uint32_t dds1Size
	 *   - byte    *dds1
	 *   - uint32_t dds2Size
	 *   - byte    *dds2
	 *   - uint32_t grassCount
	 *   - Grass    grass
	 */

	_terrain.emplace_back(std::make_unique<Graphics::Aurora::GeometryObject>(vBuf, iBuf));
}

void TRXFile::loadWATR(Common::SeekableReadStream &trx, Packet &packet) {
	Common::SeekableSubReadStream watr(&trx, trx.pos(), trx.pos() + packet.size);

	Common::UString name = Common::readStringFixed(watr, Common::kEncodingASCII, 128);

	float color[3];
	color[0] = watr.readIEEEFloatLE();
	color[1] = watr.readIEEEFloatLE();
	color[2] = watr.readIEEEFloatLE();

	watr.skip(4); // float rippleX
	watr.skip(4); // float rippleY
	watr.skip(4); // float smoothness
	watr.skip(4); // float refBias
	watr.skip(4); // float refPower
	watr.skip(4); // Unknown
	watr.skip(4); // Unknown

	Common::UString textures[3];
	for (int i = 0; i < 3; i++) {
		textures[i] = Common::readStringFixed(watr, Common::kEncodingASCII, 32);

		watr.skip(4); // float dirX
		watr.skip(4); // float dirY
		watr.skip(4); // float rate
		watr.skip(4); // float angle
	}

	watr.skip(4); // float offsetX
	watr.skip(4); // float offsetY

	uint32_t vCount = watr.readUint32LE();
	uint32_t fCount = watr.readUint32LE();

	Graphics::VertexDecl vertexDecl;

	vertexDecl.push_back(Graphics::VertexAttrib(Graphics::VPOSITION, 3, GL_FLOAT));
	vertexDecl.push_back(Graphics::VertexAttrib(Graphics::VCOLOR   , 3, GL_FLOAT));

	Graphics::VertexBuffer vBuf;
	vBuf.setVertexDeclInterleave(vCount, vertexDecl);

	float *v = reinterpret_cast<float *>(vBuf.getData());
	for (uint32_t i = 0; i < vCount; i++) {
		*v++ = watr.readIEEEFloatLE();
		*v++ = watr.readIEEEFloatLE();
		*v++ = watr.readIEEEFloatLE();

		*v++ = color[0];
		*v++ = color[1];
		*v++ = color[2];

		watr.skip(16); // texture coordinates?
	}

	Graphics::IndexBuffer iBuf;
	iBuf.setSize(fCount * 3, sizeof(uint16_t), GL_UNSIGNED_SHORT);

	uint16_t *f = reinterpret_cast<uint16_t *>(iBuf.getData());
	for (uint32_t i = 0; i < fCount; i++) {
		*f++ = watr.readUint16LE();
		*f++ = watr.readUint16LE();
		*f++ = watr.readUint16LE();
	}

	/* TODO:
	 *   - uint32_t  ddsSize
	 *   - byte     *dds
	 *   - uint32_t  flags[vCount]
	 *   - uint32_t  tileX
	 *   - uint32_t  tileY
	 */

	_water.emplace_back(std::make_unique<Graphics::Aurora::GeometryObject>(vBuf, iBuf));
}

void TRXFile::loadASWM(Common::SeekableReadStream &UNUSED(trx), Packet &UNUSED(packet)) {
}

} // End of namespace NWN2

} // End of namespace Engines
