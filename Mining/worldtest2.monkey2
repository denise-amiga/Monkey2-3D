#Import "<std>"
#Import "<mojo>"
#Import "<mojo3d>"
 
Using std..
Using mojo..
Using mojo3d..


Class chunk
	Field model:Model
	Field x:Int,y:Int,z:Int
	Field deleteme:Bool
	Method New(x:Int,y:Int,z:Int,model:Model)
		Self.x = x
		Self.y = y
		Self.z = z		
		Self.model=model
	End Method
End Class
 
Class MyWindow Extends Window
	
	Field chunklist:List<chunk>
	
	Field _scene:Scene
	
	Field _camera:Camera
	
	Field _light:Light
	
	Field _model:Model
	
	Field _rectCanvas:Canvas
	Field _rectImage:Image	
'
 	Field chunkwidth:Int=16
 	Field chunkheight:Int=16
 	Field chunkdepth:Int=16

	Field worldwidth:Int=600
	Field worldheight:Int=80
	Field worlddepth:Int=600
	Field worldmap:Int[,,]


	Method New()

		Local t:Time=Time.Now()
		Local ts:String=t.ToString()
		Local a:Int = Int(ts.Slice(16))+Microsecs()
		
		SeedRnd(a)
		RenderTexture()	
		worldmap = New Int[worldwidth,worldheight,worlddepth]
		generateworld()
		chunklist = New List<chunk>
		'get scene
		'
		_scene=Scene.GetCurrent()
 
		'create camera
		'
		_camera=New Camera
		_camera.Near=.1
		_camera.Far=1000
		_camera.Move( 50,60,35 )
		_camera.PointAt(New Vec3f(0,50,0))
		
		
		'create light
		'
		_light=New Light
		_light.Move(110,110,120)
		_light.CastsShadow = False 'slow! on low ends if true
		_light.PointAt(New Vec3f(0,0,0))
'		_light.RotateX( 90 )	'aim directional light downwards - 90 degrees.
		
'		_rectImage=New Image( 256, 256 )
'		RenderTexture()
'
'		_rectImage=New Image( 256, 256 )
'	 
'		_rectCanvas=New Canvas( _rectImage )

'		'texture temp
'		Local mesh:=createcube(0,0,0)
'		_model = New Model()
'		_model.Mesh=mesh
'		_model.Materials = _model.Materials.Resize(mesh.NumMaterials)	
'	 	Local sm:= New PbrMaterial()		
'		_rectImage=New Image( 256, 256 )	 
'		_rectCanvas=New Canvas( _rectImage )	
'		sm.ColorTexture = _rectImage.Texture
'	 	sm.ColorTexture.Flags = TextureFlags.FilterMipmap	
'		'sm.CullMode=CullMode.None	  
'		_model.Materials[mesh.NumMaterials - 1] = sm
'	 	
	 	'Local x:Int=0
	 	'Local y:Int=0
	 	'Local z:Int=0
		'Local model:=createmodel(x*chunkwidth,y*chunkheight,z*chunkdepth)	 
		
		updateworld()	 		
	End Method
	
	Method createmodel:Model(worldx:Int,worldy:Int,worldz:Int)
		Local model:Model
		
		'Here we create our chunk array
		'Local chunk:Int[,,] = New Int[chunkwidth,chunkheight,chunkdepth]

	
		'Here we create our chunk mesh
		
		Local chunkmesh:= New Mesh()
		For Local z:Int=0 Until chunkdepth
		For Local y:Int=0 Until chunkheight
		For Local x:Int=0 Until chunkwidth
			Local z2:Int=z+worldz
			Local y2:Int=y+worldy
			Local x2:Int=x+worldx
			If z2<0 Or y2<0 Or x2<0 Or z2>=worlddepth Or y2>=worldheight Or x2>=worldwidth Then Continue
			If worldmap[x2,y2,z2] <> 0 Then 
				Local sides:Bool[] = New Bool[6]
				If z2-1>=0 And worldmap[x2,y2,z2-1] <> 0 Then sides[0] = False Else sides[0] = True
				If x2-1>=0 And worldmap[x2-1,y2,z2] <> 0 Then sides[3] = False Else sides[3] = True
				If z2+1<chunkdepth And worldmap[x2,y2,z2+1] <> 0 Then sides[1] = False Else sides[1] = True
				If x2+1<chunkwidth And worldmap[x2+1,y2,z2] <> 0 Then sides[2] = False Else sides[2] = True
				If y2+1<chunkheight And worldmap[x2,y2+1,z2] <> 0 Then sides[4] = False Else sides[4] = True
				If y2-1>=0 And worldmap[x2,y2-1,z2] <> 0 Then sides[5] = False Else sides[5] = True				
				Local mesh2:=createcube(x2*2,y2*2,z2*2,sides)								
				chunkmesh.AddMesh(mesh2)
			endif
		Next
		Next
		Next 
		' Here we create our model containing the chunk
		chunkmesh.UpdateNormals()

	
		model=New Model
		'If there is no mesh created then return empty model
		If chunkmesh.NumIndices = 0 Then Return model
		'_model.Mesh=chunkmesh		
		'_model.Material=New PbrMaterial( Color.Green )
		'_model.Material.CullMode=CullMode.None
 		'_model.Move(2,0,0)
		model.Mesh=chunkmesh
		model.Materials = model.Materials.Resize(chunkmesh.NumMaterials)	

	 	Local sm:= New PbrMaterial()
		
		'_rectImage=New Image( 256, 256 )
	 
		'_rectCanvas=New Canvas( _rectImage )
	
		sm.ColorTexture = _rectImage.Texture
	 	sm.ColorTexture.Flags = TextureFlags.FilterMipmap	
		'sm.CullMode=CullMode.None
	 
 		
		model.Materials[chunkmesh.NumMaterials - 1] = sm
		Return model
'				
	End Method
	
	Method OnRender( canvas:Canvas ) Override
 
		RequestRender()
		RenderTexture()
		'RenderTexture()
		'_model.RotateY( 1 )
		'_model.RotateZ( -1 )
		'_model.RotateX( 1 )
		'controls()
		Fly(_camera)
		updateworld()
		'_scene.Update()
		_scene.Render( canvas,_camera )
 		 		
		canvas.DrawText( "Width="+Width+", Height="+Height+", FPS="+App.FPS,0,0 )
		canvas.DrawText( "mx"+_camera.Position.x/chunkwidth+", my="+_camera.Position.y/chunkheight+", FPS="+_camera.Position.z/chunkdepth,0,30 )
		
		If Keyboard.KeyReleased(Key.Escape) Then App.Terminate()
	End Method

Method updateworld()	 	
		Local x2:Int=(_camera.Position.x/2) / chunkwidth
		Local z2:Int=(_camera.Position.z/2) / chunkdepth
		Local y2:Int=(_camera.Position.y/2) / chunkheight
		'Print x2+","+y2+","+z2
		Local mlx:Stack<Int> = New Stack<Int>
		Local mly:Stack<Int> = New Stack<Int>
		Local mlz:Stack<Int> = New Stack<Int>
		For Local z3:Int=z2-2 To z2+2
		For Local y3:Int=y2-2 To y2+2
		For Local x3:Int=x2-2 To x2+2
			If x3<0 Or y3<0 Or z3<0 Then Continue
			Local makeit:Bool=True
			For Local i:=Eachin chunklist
				If i.x = x3 And i.y = y3 And i.z = z3 Then makeit = False
			Next
			If makeit = True
				mlz.Push(z3)
				mly.Push(y3)
				mlx.Push(x3)
			End If
		Next
		Next
		Next
		'For Local i:int=0 Until 6
		'chunklist.Add(New chunk(5,5,5,createmodel(i*chunkwidth,i*chunkheight,i*chunkdepth))						)
		'Next
		For Local i:Int=0 Until mlx.Length
			Local x:Int=mlx.Get(i)			
			Local y:Int=mly.Get(i)
			Local z:Int=mlz.Get(i)'			
			'Local model:=createmodel(x*chunkwidth,y*chunkheight,z*chunkdepth)
			chunklist.Add(New chunk(x,y,z,createmodel(x*chunkwidth,y*chunkheight,z*chunkdepth))						)
		Next

		' If distance between chunks and camera is to large then remove them		
		For Local i:=Eachin chunklist
			If distance(i.x,i.z,_camera.Position.x/2/chunkwidth,_camera.Position.z/2/chunkdepth) > 5
				i.model.Destroy()
				i.deleteme = True
			End If
		Next
		For Local i:=Eachin chunklist
			If i.deleteme = True Then chunklist.Remove(i)
		Next
End Method

Method createcube:Mesh(x:Float=0,y:Float=0,z:Float=0,sides:Bool[])
	
	'create cube mesh
	'
	Local vertices:=New Vertex3f[24]
	'front
	vertices[0].position=New Vec3f( -1+x, 1+y,-1+z )'left front top
	vertices[1].position=New Vec3f(  1+x, 1+y,-1+z )'right front top
	vertices[2].position=New Vec3f(  1+x,-1+y,-1+z )'right front bottom
	vertices[3].position=New Vec3f( -1+x,-1+y,-1+z )'left front bottom
	'back
	vertices[4].position=New Vec3f(  1+x, 1+y, 1+z )'right back top
	vertices[5].position=New Vec3f( -1+x, 1+y, 1+z )'left back top
	vertices[6].position=New Vec3f( -1+x,-1+y, 1+z )'left back bottom
	vertices[7].position=New Vec3f(  1+x,-1+y, 1+z )'right back bottom
	'right
	vertices[8].position=New Vec3f(  1+x, 1+y,-1+z )'right front top
	vertices[9].position=New Vec3f(  1+x, 1+y, 1+z )'right back top
	vertices[10].position=New Vec3f( 1+x,-1+y, 1+z )'right back bottom
	vertices[11].position=New Vec3f( 1+x,-1+y,-1+z )'right front bottom
	'left
	vertices[12].position=New Vec3f( -1+x, 1+y, 1+z )'left back top
	vertices[13].position=New Vec3f( -1+x, 1+y,-1+z )'left front top
	vertices[14].position=New Vec3f( -1+x,-1+y,-1+z )'left front bottom
	vertices[15].position=New Vec3f( -1+x,-1+y, 1+z )'left back bottom
	'top
	vertices[16].position=New Vec3f( -1+x, 1+y, 1+z )'left back top
	vertices[17].position=New Vec3f(  1+x, 1+y, 1+z )'right back top
	vertices[18].position=New Vec3f(  1+x, 1+y,-1+z )'right front top
	vertices[19].position=New Vec3f( -1+x, 1+y,-1+z )'left front top
	'bottom
	vertices[20].position=New Vec3f( -1+x,-1+y,-1+z )'left front bottom
	vertices[21].position=New Vec3f(  1+x,-1+y,-1+z )'right front bottom
	vertices[22].position=New Vec3f(  1+x,-1+y, 1+z )'right back bottom
	vertices[23].position=New Vec3f( -1+x,-1+y, 1+z )'left back bottom
	

'  Texture coordinates represent coordinates within the image, where 
'	0,0=top left, 1,0=top right, 1,1=bottom right, 0,1=bottom left
	
	'front texture
	vertices[0].texCoord0 = New Vec2f(0,0)
	vertices[1].texCoord0 = New Vec2f(1,0)
	vertices[2].texCoord0 = New Vec2f(1,1)
	vertices[3].texCoord0 = New Vec2f(0,1)
	'back texture		
	vertices[4].texCoord0 = New Vec2f(0,0)
	vertices[5].texCoord0 = New Vec2f(1,0)
	vertices[6].texCoord0 = New Vec2f(1,1)
	vertices[7].texCoord0 = New Vec2f(0,1)
	'right texture
	vertices[8].texCoord0 = New Vec2f(0,0)
	vertices[9].texCoord0 = New Vec2f(1,0)
	vertices[10].texCoord0 = New Vec2f(1,1)
	vertices[11].texCoord0 = New Vec2f(0,1)
	'left texture
	vertices[12].texCoord0 = New Vec2f(0,0)
	vertices[13].texCoord0 = New Vec2f(1,0)
	vertices[14].texCoord0 = New Vec2f(1,1)
	vertices[15].texCoord0 = New Vec2f(0,1)
	'top texture
	vertices[16].texCoord0 = New Vec2f(0,0)
	vertices[17].texCoord0 = New Vec2f(1,0)
	vertices[18].texCoord0 = New Vec2f(1,1)
	vertices[19].texCoord0 = New Vec2f(0,1)
	'bottom texture
	vertices[20].texCoord0 = New Vec2f(0,0)
	vertices[21].texCoord0 = New Vec2f(1,0)
	vertices[22].texCoord0 = New Vec2f(1,1)
	vertices[23].texCoord0 = New Vec2f(0,1)

'		 
	Local indices:=New UInt[36]
	Local cnt:Int=0
	'front
	If sides[0]
	indices[cnt]=0;cnt+=1
	indices[cnt]=1;cnt+=1
	indices[cnt]=2;cnt+=1
	indices[cnt]=0;cnt+=1
	indices[cnt]=2;cnt+=1
	indices[cnt]=3;cnt+=1
	End if
	'back side
	If sides[1]
	indices[cnt]=4;cnt+=1
	indices[cnt]=5;cnt+=1
	indices[cnt]=6;cnt+=1
	indices[cnt]=4;cnt+=1
	indices[cnt]=6;cnt+=1
	indices[cnt]=7;cnt+=1
	End If
	'right side
	If sides[2]
	indices[cnt]=8;cnt+=1
	indices[cnt]=9;cnt+=1
	indices[cnt]=10;cnt+=1
	indices[cnt]=8;cnt+=1
	indices[cnt]=10;cnt+=1
	indices[cnt]=11;cnt+=1
	End if
	' left side
	If sides[3]
	indices[cnt]=12;cnt+=1
	indices[cnt]=13;cnt+=1
	indices[cnt]=14;cnt+=1
	indices[cnt]=12;cnt+=1
	indices[cnt]=14;cnt+=1
	indices[cnt]=15;cnt+=1	
	End If
	'top side
	If sides[4]
	indices[cnt]=16;cnt+=1
	indices[cnt]=17;cnt+=1
	indices[cnt]=18;cnt+=1
	indices[cnt]=16;cnt+=1
	indices[cnt]=18;cnt+=1
	indices[cnt]=19;cnt+=1
	End If
	'bottom side
	If sides[5]
	indices[cnt]=20;cnt+=1
	indices[cnt]=21;cnt+=1
	indices[cnt]=22;cnt+=1
	indices[cnt]=20;cnt+=1
	indices[cnt]=22;cnt+=1
	indices[cnt]=23;cnt+=1
	End If
	
	Return New Mesh( vertices,indices )		
	
End Method

'
'	'sides (0-front,1=left,2=back,3=right,4=top,5=bottom)
'	'x,y,z is location in the chunk
'	Method createcube:Mesh(x:Float=0,y:Float=0,z:Float=0,sides:Bool[])
'		
'		'create cube mesh
'		'
'		Local vertices:=New Vertex3f[8]
'		vertices[0].position=New Vec3f( -1+x, 1+y,-1+z )'left front top
'		vertices[1].position=New Vec3f(  1+x, 1+y,-1+z )'right front top
'		vertices[2].position=New Vec3f(  1+x,-1+y,-1+z )'right front bottom
'		vertices[3].position=New Vec3f( -1+x,-1+y,-1+z )'left front bottom
'		vertices[4].position=New Vec3f( -1+x, 1+y, 1+z )'left back top
'		vertices[5].position=New Vec3f( -1+x,-1+y, 1+z )'left back bottom
' 		vertices[6].position=New Vec3f(  1+x, 1+y, 1+z )'right back top
' 		vertices[7].position=New Vec3f(  1+x,-1+y, 1+z )'right back bottom
'
'
''  Texture coordinates represent coordinates within the image, where 
''	0,0=top left, 1,0=top right, 1,1=bottom right, 0,1=bottom left
'		vertices[0].texCoord0 = New Vec2f(0,0)
'		vertices[1].texCoord0 = New Vec2f(1,0)
'		vertices[2].texCoord0 = New Vec2f(1,1)
'		vertices[3].texCoord0 = New Vec2f(0,1)
'		
'		vertices[4].texCoord0 = New Vec2f(1,0)
'		vertices[5].texCoord0 = New Vec2f(0,1)
'		vertices[6].texCoord0 = New Vec2f(0,0)
'		vertices[7].texCoord0 = New Vec2f(0,1)		 		
'
' 		Local inds:Int=0
' 		For Local i:Int=0 Until 6
'	 		If sides[i] = True Then inds+=6
'	 	Next
' 		
'		Local indices:=New UInt[inds]
'		
'		Local cnt:Int=0
'		'front
'		If sides[0] = True
'		indices[cnt]=0;cnt+=1
'		indices[cnt]=1;cnt+=1
'		indices[cnt]=2;cnt+=1
'		indices[cnt]=0;cnt+=1
'		indices[cnt]=2;cnt+=1
'		indices[cnt]=3;cnt+=1
'		End if
'		If sides[1] = True
'		' left side
'		indices[cnt]=4;cnt+=1
'		indices[cnt]=0;cnt+=1
'		indices[cnt]=3;cnt+=1
'		indices[cnt]=4;cnt+=1
'		indices[cnt]=3;cnt+=1
'		indices[cnt]=5;cnt+=1
'		End If
'		If sides[2] = True
'		'back side
'		indices[cnt]=6;cnt+=1
'		indices[cnt]=4;cnt+=1
'		indices[cnt]=5;cnt+=1
'		indices[cnt]=6;cnt+=1
'		indices[cnt]=5;cnt+=1
'		indices[cnt]=7;cnt+=1
'		End If
'		If sides[3] = True
'		'right side
'		indices[cnt]=1;cnt+=1
'		indices[cnt]=6;cnt+=1
'		indices[cnt]=7;cnt+=1
'		indices[cnt]=1;cnt+=1
'		indices[cnt]=7;cnt+=1
'		indices[cnt]=2;cnt+=1
'		End If
'		If sides[4] = True
'		'top side
'		indices[cnt]=0;cnt+=1
'		indices[cnt]=4;cnt+=1
'		indices[cnt]=6;cnt+=1
'		indices[cnt]=0;cnt+=1
'		indices[cnt]=6;cnt+=1
'		indices[cnt]=1;cnt+=1
'		End If
'		If sides[5] = true
'		'bottom side
'		indices[cnt]=7;cnt+=1
'		indices[cnt]=5;cnt+=1
'		indices[cnt]=3;cnt+=1
'		indices[cnt]=7;cnt+=1
'		indices[cnt]=3;cnt+=1
'		indices[cnt]=2;cnt+=1
'		End If
'				
'		Return New Mesh( vertices,indices )		
'		
'	End Method
'	
	Method controls()
		If Keyboard.KeyDown(Key.W) Then _camera.Move(0,0,.5)
		If Keyboard.KeyDown(Key.S) Then _camera.Move(0,0,-.5)
		If Keyboard.KeyDown(Key.A) Then _camera.Move(-.5,0,0)
		If Keyboard.KeyDown(Key.D) Then _camera.Move(.5,0,0)
		If Keyboard.KeyDown(Key.Up) Then _camera.Rotate(1,0,0)
		If Keyboard.KeyDown(Key.Down) Then _camera.Rotate(-1,0,0)
		If Keyboard.KeyDown(Key.Left) Then _camera.Rotate(0,1,0)
		If Keyboard.KeyDown(Key.Right) Then _camera.Rotate(0,-1,0)
	End Method
	
	Method RenderTexture()
		If Not _rectCanvas Then
			_rectImage = New Image(256,256)
			_rectCanvas=New Canvas( _rectImage )
 
		Endif
		
		'This should be orange with white text on
		'But since I'm drawing something in the top left corner -
		'I'm just getting that top left pixel on the entire rectangle
		
		_rectCanvas.Clear( Color.Blue )
		_rectCanvas.Color = Color.White
		_rectCanvas.DrawText( "Hello World", Rnd(8,12), 8 )
		_rectCanvas.Color = Color.Orange
		_rectCanvas.DrawRect( 50, 50 , 200 ,90) 'White in the top left
		
		
		
		_rectCanvas.Flush()
		
	End	Method
	
	Method generateworld()
		'underground
		
		For Local z:Int=0 Until worlddepth
		For Local x:Int=0 Until worldwidth
		For Local y:Int=0 Until 20
			worldmap[x,y,z] = 1
		Next
		Next
		Next

		'dig out (dists) circles on circles
		For Local i:Int=0 Until (worldwidth+worlddepth)/12
			Local x1:Int=Rnd(worldwidth)
			Local z1:Int=Rnd(worlddepth)
			Local h:Int=Rnd(1,3)
			If Rnd() < .15 Then h=Rnd(3,10)
			For Local ii:Int=0 Until h
				x1+=Rnd(-5,5)
				z1+=Rnd(-5,5)				
				Local radius:Int=Rnd(2,30)
				For Local z2:Int=-radius To radius
				For Local x2:Int=-radius To radius
					If (z2*z2+x2*x2) <= radius*radius+radius*0.8
						Local x3:Int = x1+x2
						Local z3:Int = z1+z2
						If x3>=0 And z3>=0 And x3<worldwidth And z3<worlddepth
							Local yer:Int
							For Local y3:Int=worldheight-5 Until 2 Step -1
								If worldmap[x3,y3,z3] <> 0
									yer=y3
									Exit
								End If
							Next
							'yer = 20
							worldmap[x3,yer,z3] = 0
						End If
					End If
				Next
				Next
			Next
		Next

		'drop some elevations (dists) circles on circles
		For Local i:Int=0 Until (worldwidth+worlddepth)/12
			Local x1:Int=Rnd(worldwidth)
			Local z1:Int=Rnd(worlddepth)
			Local h:Int=Rnd(3,10)
			If Rnd()<0.05 Then h=15
			For Local ii:Int=0 Until h
				x1+=Rnd(-5,5)
				z1+=Rnd(-5,5)				
				Local radius:Int=Rnd(2,30)
				For Local z2:Int=-radius To radius
				For Local x2:Int=-radius To radius
					If (z2*z2+x2*x2) <= radius*radius+radius*0.8
						Local x3:Int = x1+x2
						Local z3:Int = z1+z2
						If x3>=0 And z3>=0 And x3<worldwidth And z3<worlddepth
							Local yer:Int
							For Local y3:Int=worldheight-5 Until 2 Step -1
								If worldmap[x3,y3,z3] <> 0
									yer=y3+1
									Exit
								End If
							Next
							'yer = 20
							worldmap[x3,yer,z3] = 1
						End If
					End If
				Next
				Next
			Next
		Next


	'	For Local i:Int=0 Until 50000
	'		worldmap[Rnd(worldwidth),Rnd(worldheight),Rnd(worlddepth)] = 1
	'	Next
		'Return
		'mountains
		
		' Caves and Rocky mountains
		 For Local xii:Int=0 Until (worldwidth+worlddepth)
			Local under:Bool=False
			If Rnd()<.8 Then under=True
			Local x:Float=Rnd(worldwidth)
			Local y:Float=20
			Local z:Float=Rnd(worlddepth)
			Local dx:Float=Rnd(-1,1)
			Local dy:Float=Rnd(-1,1)
			Local dz:Float=Rnd(-1,1)
			Local lenny:Int=Rnd(150,500)
			Local tiepe:Bool=False
			
			If Rnd()<.01 And under=True Then tiepe=True
			If under=False Then tiepe = false
			For Local i:Int=0 Until lenny
				
				x+=dx
				y+=dy
				z+=dz
				If Rnd() < .2 Then dx = Rnd(-1,1)
				If Rnd() < .2 Then dy = Rnd(-1,.5)
				If Rnd() < .2 Then dz = Rnd(-1,1)
				If x<1 Or y<1 Or z<1 Or x>=worldwidth-1 Or y>=worldheight-1 Or z>=worlddepth-1 Then Continue
				
				If under=False And x>=10 And y+4>=10 And z>=10 And x<worldwidth-10 And y+4<worldheight-10 And z<worlddepth-10
					'If worldmap[x+(dx*10),y+4,z+(dz*10)] = 0 Then dy=-1
					If y>worldheight-20 Then dy=-1
				End If
				
				
				
				Local bg:Int=-3
				If y<21 Then bg=Rnd(-10,-5)
				
				'tunnels
				If under=True Then bg=Rnd(-3,-1)
				'rooms in tunnels
				If under=True And Rnd()<.015 And y<10 And y>4 Then bg=-6		
				
				If under=True And Rnd()<.009 Then 
					If tiepe=False Then tiepe=True Else tiepe=False
				End If
				
				If tiepe=True Then
					For Local y1:Int=bg To Abs(bg)
					For Local x1:Int=bg To Abs(bg)'Rnd(bg,-1) To Rnd(1,Abs(bg))
					For Local z1:Int=bg To Abs(bg)'Rnd(bg,-1) To Rnd(1,Abs(bg))
						Local x2:Int=x+x1
						Local y2:Int=y+y1
						Local z2:Int=z+z1
						If x2<=1 Or y2<1 Or z2<1 Or x2>=worldwidth-1 Or y2>=worldheight-1 Or z2>=worlddepth-1 Then Continue
						'If Rnd() < .9 Then
						If under=False Then
							worldmap[x2,y2,z2] = 1
						Else
							If worldmap[x2,y2,z2] = 1 Then worldmap[x2,y2,z2] = 0
						End if
						'End If
					Next
					Next
					Next
				Else
					For Local y1:Int=bg/2 To Abs(bg/2)
					For Local x1:Int=Rnd(bg,-1) To Rnd(1,Abs(bg))
					For Local z1:Int=Rnd(bg,-1) To Rnd(1,Abs(bg))
						Local x2:Int=x+x1
						Local y2:Int=y+y1
						Local z2:Int=z+z1
						If x2<=1 Or y2<1 Or z2<1 Or x2>=worldwidth-1 Or y2>=worldheight-1 Or z2>=worlddepth-1 Then Continue
						'If Rnd() < .9 Then
						If under=False Then
							worldmap[x2,y2,z2] = 1
						Else
							If worldmap[x2,y2,z2] = 1 Then worldmap[x2,y2,z2] = 0
						End if
						'End If
					Next
					Next
					Next
				End If			
			Next
		Next		
		
		
		
		
		
	End Method
	
	Function Fly( entity:Entity)
		
		Const rspeed:=2.0
	
		If Keyboard.KeyDown( Key.Up )
			entity.RotateX( rspeed )
		Else If Keyboard.KeyDown( Key.Down )
			entity.RotateX( -rspeed )
		Endif
		
		If Keyboard.KeyDown( Key.A )
			entity.RotateZ( rspeed )
		Else If Keyboard.KeyDown( Key.D )
			entity.RotateZ( -rspeed )
		Endif
		
		If Keyboard.KeyDown( Key.Left )
			entity.RotateY( rspeed,True )
		Else If Keyboard.KeyDown( Key.Right )
			entity.RotateY( -rspeed,True )
		Endif
	
		If Mouse.ButtonDown( MouseButton.Left )
			'If Mouse.X<view.Width/3
				entity.RotateY( rspeed,True )
			'Else If Mouse.X>view.Width/3*2
				entity.RotateY( -rspeed,True )
			'Else
			'	entity.Move( New Vec3f( 0,0,.1 ) )
			'Endif
		Endif
		
		If Keyboard.KeyDown( Key.W )
			entity.MoveZ( .4 )
		Else If Keyboard.KeyDown( Key.S )
			entity.MoveZ( -.4 )
		Endif
			
	End Function
		
	
	
    Function distance:Int(x1:Int,y1:Int,x2:Int,y2:Int)   
    	Return Abs(x2-x1)+Abs(y2-y1)   
    End Function 	
	
End Class
 
Function Main()
	
	New AppInstance
	New MyWindow
	App.Run()	
End