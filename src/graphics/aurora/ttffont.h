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
 *  A TrueType font.
 */

#ifndef GRAPHICS_AURORA_TTFFONT_H
#define GRAPHICS_AURORA_TTFFONT_H

#include <vector>
#include <map>
#include <memory>

#include "src/common/types.h"

#include "src/graphics/font.h"

#include "src/graphics/aurora/texturehandle.h"

#include "src/graphics/mesh/meshfont.h"

#include "src/graphics/shader/shaderrenderable.h"

namespace Common {
	class UString;
}

namespace Graphics {

class Surface;
class TTFRenderer;

namespace Aurora {

class TTFFont : public Graphics::Font {
public:
	TTFFont(Common::SeekableReadStream *ttf, int height);
	TTFFont(const Common::UString &name, int height);
	~TTFFont();

	float getWidth (uint32_t c) const;
	float getHeight()           const;

	void draw(uint32_t c) const;

	void buildChars(const Common::UString &str);

	/** Bind the font for rendering. Must be performed before render is called.
	 *
	 *  @param transform  Base modelview transform. Under most circumstances
	 *                    this is expected to be the identity matrix.
	 */
	virtual void renderBind(const glm::mat4 &transform) const;
	virtual void render(uint32_t c, float &x, float &y, float *rgba) const;
	virtual void renderUnbind() const;

private:
	/** A texture page filled with characters. */
	struct Page {
		Surface *surface;
		TextureHandle texture;

		bool needRebuild;

		uint32_t curX;
		uint32_t curY;

		uint32_t heightLeft;
		uint32_t widthLeft;

		Page();

		void rebuild();
	};

	/** A font character. */
	struct Char {
		float width;

		float tX[4], tY[4];
		float vX[4], vY[4];

		size_t page;
	};


	std::unique_ptr<TTFRenderer> _ttf;

	std::vector<std::unique_ptr<Page>> _pages;
	std::map<uint32_t, Char> _chars;

	std::map<uint32_t, Char>::const_iterator _missingChar;
	float _missingWidth;

	uint32_t _height;

	Mesh::MeshFont *_mesh;
	Shader::ShaderMaterial *_material;
	Shader::ShaderRenderable *_renderable;


	void load(Common::SeekableReadStream *ttf, int height);

	void rebuildPages();
	void addChar(uint32_t c);
	void drawMissing() const;
};

} // End of namespace Aurora

} // End of namespace Graphics

#endif // GRAPHICS_AURORA_TTFFONT_H
