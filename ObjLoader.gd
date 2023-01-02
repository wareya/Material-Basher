class_name ObjLoader

static func parse_obj(text : String):
    var verts = []
    var uvs = []
    var normals = []
    var faces = []
    
    var n = 0
    for line in text.split("\n"):
        n += 1
        line = line.split("#")[0]
        var data : Array = Array((line as String).split(" ", false))
        for i in data.size():
            data[i] = data[i].strip_edges()
        if data.size() < 2:
            continue
        var type = data.pop_front()
        if type == "v":
            verts.push_back(Vector3(data[0].to_float(), data[1].to_float(), data[2].to_float()))
        elif type == "vt":
            var u = data[0].to_float()
            var v = 0
            if data.size() >= 1:
                v = 1.0 - data[1].to_float()
            uvs.push_back(Vector2(u, v))
        elif type == "vn":
            normals.push_back(Vector3(data[0].to_float(), data[1].to_float(), data[2].to_float()))
        elif type == "f":
            var face_v = PoolVector3Array()
            var face_n = PoolVector3Array()
            var face_uv = PoolVector2Array()
            data.invert()
            for _susbtr in data:
                var substr : String = _susbtr
                var indexes = substr.split("/")
                while indexes.size() < 3:
                    indexes.push_back("")
                face_v.push_back(verts[indexes[0].to_int()-1])
                if indexes[2].is_valid_integer():
                    face_n.push_back(normals[indexes[2].to_int()-1])
                if indexes[1].is_valid_integer():
                    face_uv.push_back(uvs[indexes[1].to_int()-1])
            if face_n.size() == 0:
                var normal = (face_v[0] - face_v[1]).cross(face_v[1] - face_v[2])
                if face_v.size() == 4:
                    normal = (face_v[0] - face_v[2]).cross(face_v[3] - face_v[1])
                face_n = []
                for i in face_n.size():
                    face_n.push_back(normal)
            elif face_n.size() != face_v.size():
                var normal = face_n[0]
                face_n = []
                for i in face_n.size():
                    face_n.push_back(normal)
            
            faces.push_back([face_v, face_n, face_uv])
    
    var stool = SurfaceTool.new()
    stool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        #stool.add_vertex()
        #stool.add_normal(face[1])
        #stool.add_uv(face[2])
        stool.add_triangle_fan(face[0], face[2], PoolColorArray(), PoolVector2Array(), face[1])
    
    return stool.commit()
