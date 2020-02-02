# Godot_sky_shader
This project adds a dynamic sky shader to your project. It is based on https://github.com/danilw/godot-utils-and-other.

Complete feature list
* day-night-cycle
* Sun
* Moon
* Stars
* Clouds
* God Rays (via [God Rays Plugin](https://github.com/SIsilicon/Godot-God-Rays-Plugin) by @SIsilicon)
  * the combination of both has a noticable performance impact

[![sky](https://github.com/Lexpartizan/Godot_sky_shader/blob/master/preview1.jpg)](https://www.youtube.com/watch?v=fzUHa1BbOd4) 

The Third Person Controller used in the demo scene uses the code from https://github.com/NIK0666/GodotThirdPersonController, as featured in the following video: https://youtu.be/jxtUtUo4aEI

# Support

The shader and demo scenes target Godot 3.2.  
There is a *.zip file which contains a subset of this project's content and works in Godot 3.1.

# How-to use it

The demo scene Sky.tscn showcases some of the abilities of this dynamic sky.

Parameters in the Sky scene:
* Moon Phase: Covers the moon with a shadow from top-left of the moon to the bottom-right (and vice-verca)
* Coverage: Specifies how much the sky is covered by clouds
* Height: How close the clouds are to the viewer
* Quality Steps: If the steps are < 20, the 3D clouds are exchanged with 2D clouds
* Wind Strength: Speed of cloud movement
* Lightning Strike: brightens the sky for less than a second

Additional changes can be made which are not currently exposed in the GUI of the demo scene, such as
* traversal route (speed & direction) of sun and moon
* wind direction, ie. direction the clouds move

Your own scene needs
* a WorldEnvironment
  * Mode: Sky
  * Sky: PanoramaSky
* a light, e.g. a directional light
* one Viewport, with a child node of type Sprite, for the sky texture
  * in the CanvasItem section: create a new ShaderMaterial and assign the CloudlessShader.shader to it
* another Viewport, with a child node of type Sprite, for the cloud texture (if you want clouds)
  * in the CanvasItem section: create a new ShaderMaterial and assign the Clouds.shader to it

# Known Issues

* Stretched sun and moon (see issue #5)
* Flickering on the cloud edges
* A vertical seam on the sphere of the PanoramaSky is visible when the clouds move over it (see issue #2)