require 'rubygems'
require 'opengl'
#require 'glew'
require 'devil'

@vertex_buffer = nil
@element_buffer = nil
@textures = nil
@uniforms = {}
@attributes = {}
@fade_factor = 0

def make_resources
  @vertex_buffer = make_buffer GL::ARRAY_BUFFER, @g_vertex_buffer_data
  @element_buffer = make_buffer GL::ELEMENT_ARRAY_BUFFER, @g_element_buffer_data
  @textures = [
    make_texture("hello1.tga"),
    make_texture("hello2.tga")
  ]

  @program = make_program(make_shader(GL::GL_VERTEX_SHADER, 'hello.v.glsl'),make_shader(GL::GL_FRAGMENT_SHADER, 'hello.f.glsl'))

  @uniforms[:fade_factor] = GL.GetUniformLocation(@program, 'fade_factor')
  @uniforms[:textures] = { 0 => GL.GetUniformLocation(@program, 'textures[0]'), 1 => GL.GetUniformLocation(@program, 'textures[1]') }

  @attributes[:position] = GL.GetAttribLocation(@program, 'position')
end

def make_buffer target, buffer_data
  buffer = GL.GenBuffers(1).first
  GL.BindBuffer target, buffer

  packed_buffer_data = (target == GL::ELEMENT_ARRAY_BUFFER) ? buffer_data.pack("i*") : buffer_data.pack("f*")

  GL.BufferData target, buffer_data.length*4, packed_buffer_data, GL::STATIC_DRAW
  return buffer
end

def make_texture filename
  name = IL.GenImages(1).first
  IL.BindImage(name)
  IL.LoadImage(filename)
  IL.ConvertImage(IL::RGBA, IL::UNSIGNED_BYTE)

  pixels = IL.ToBlob
  width = IL.GetInteger(IL::IMAGE_WIDTH)
  height = IL.GetInteger(IL::IMAGE_HEIGHT)

  texture = Gl.glGenTextures(1).first
  GL.BindTexture Gl::GL_TEXTURE_2D, texture
  GL.TexParameteri Gl::GL_TEXTURE_2D, Gl::GL_TEXTURE_MIN_FILTER, Gl::GL_LINEAR
  GL.TexParameteri Gl::GL_TEXTURE_2D, Gl::GL_TEXTURE_MAG_FILTER, Gl::GL_LINEAR
  GL.TexParameteri Gl::GL_TEXTURE_2D, Gl::GL_TEXTURE_WRAP_S,     Gl::GL_CLAMP_TO_EDGE
  GL.TexParameteri Gl::GL_TEXTURE_2D, Gl::GL_TEXTURE_WRAP_T,     Gl::GL_CLAMP_TO_EDGE
  GL.TexImage2D Gl::GL_TEXTURE_2D, 0, Gl::GL_RGBA8, width, height, 0, Gl::GL_RGBA, Gl::GL_UNSIGNED_BYTE, pixels
  return texture
end

def make_shader type, filename
  source = File.read(filename)

  shader = GL.CreateShader type
  GL.ShaderSource shader, source
  GL.CompileShader shader

  if !GL.GetShaderiv(shader, GL::GL_COMPILE_STATUS)
    puts GL.GetShaderInfoLog shader
    GL.DeleteShader shader
    nil
  else
    shader
  end
end

def make_program vertex_shader, fragment_shader
  program = GL.CreateProgram
  GL.AttachShader program, vertex_shader
  GL.AttachShader program, fragment_shader
  GL.LinkProgram program

  if !GL.GetProgramiv(program, GL::GL_LINK_STATUS)
    puts GL.GetProgramInfoLog program
    GL.DeleteProgram program
    nil
  else
    program
  end

end

@g_vertex_buffer_data = [
  -1,-1,
   1,-1,
  -1, 1,
   1, 1
]

@g_element_buffer_data = [0,1,2,3]

def render
  GL.UseProgram @program
  GL.Uniform1f @uniforms[:fade_factor], @fade_factor

  GL.ActiveTexture(GL::TEXTURE0)
  GL.BindTexture(GL::TEXTURE_2D, @textures[0])
  GL.Uniform1i @uniforms[:textures][0], 0

  GL.ActiveTexture(GL::TEXTURE1)
  GL.BindTexture(GL::TEXTURE_2D, @textures[1])
  GL.Uniform1i @uniforms[:textures][1], 1

  GL.BindBuffer GL::ARRAY_BUFFER, @vertex_buffer
  GL.VertexAttribPointer @attributes[:position], 2, GL::FLOAT, GL::FALSE, 4*2, 0
  GL.EnableVertexAttribArray @attributes[:position]

  GL.BindBuffer GL::ELEMENT_ARRAY_BUFFER, @element_buffer
  GL.DrawElements GL::TRIANGLE_STRIP, 4, GL::UNSIGNED_INT, 0

  GL.DisableVertexAttribArray @attributes[:position]

  GLUT.SwapBuffers
end

def update_fade_factor
  @fade_factor = Math.sin(GLUT.Get(GLUT::ELAPSED_TIME)*0.001)*0.5+0.5
  GLUT.PostRedisplay
end


IL.Init

Glut.glutInit
Glut.glutInitDisplayMode Glut::GLUT_RGB | Glut::GLUT_DOUBLE
Glut.glutInitWindowSize 400, 300
Glut.glutCreateWindow "Hello World"
Glut.glutDisplayFunc method(:render).to_proc
Glut.glutIdleFunc method(:update_fade_factor).to_proc
#Glew.glewInit

#puts "OpenGL 2.0 not available" and exit if Glew.glewIsSupported("GL_VERSION_2_0")==0
puts "Failed to load resources" and exit unless make_resources

Glut.glutMainLoop
