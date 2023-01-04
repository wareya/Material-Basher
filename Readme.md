# Material Basher

Material Basher is a tool made in Godot 3 for turning non-PBR textures
into PBR-workflow-compatible material data. This does not create accurate
PBR materials, it just makes it possible to use non-PBR textures in
PBR rendering pipelines without then being incredibly ugly.

![Screenshot](https://user-images.githubusercontent.com/585488/210592454-d7ee3e77-380b-4d37-b184-4cdd80e91d2b.png)

## Features

- normal map generation via octave analysis
  (exports both GL-style and DX-style normal maps)
- depth map* generation via octave analysis
  (displacement map generation to come later)
- ambient occlusion map generation via blue-based divot analysis
  (similar in spirit to difference-of-gaussians)
- metallicity map generation via color mapping
- roughness map generation via color mapping
- ambient occlusion removal from albedo texture (shading removal)
- many different preview shapes (sphere, cube, cylinders, planes)
- custom preview meshes (drag and drop a .obj file with proper UVs)

(* height maps can already be generated but won't display properly
   and will work strangely with ambient occlusion map generation)

## How to use

Drag and drop a texture onto the window, then play around with the
buttons and sliders until the material looks good. Have fun!

What? Making non-PBR textures look good with PBR properties is an art,
not a science. Practice, practice, practice.

## SLOW.

Normal map, depth map, and AO map generation currently use a very slow
texture sampling technique in a very inefficient and wasteful way, in
order to avoid interpolation artifacts. I will fix this in the future.

Also, all the expensive stuff is done on the GPU in GLSL shaders, so if
you have a weak or integrated GPU things might not work well at all.

# License

Copyright 2023 "Wareya" (wareya@gmail.com) and any contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Third-party licenses

Third party copyright and license info for Godot and its dependencies can be
found in the third party copyright info text file.


Also uses Native Dialogs under the MIT license, as follows:

MIT License

Copyright (c) 2022 Tomás Espejo Gómez

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
