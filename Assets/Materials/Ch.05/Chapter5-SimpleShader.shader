// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 5/Simple Shader" {
    Properties{
        _Color ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader {
        Pass {
            CGPROGRAM

            #pragma vertex vert // Vertex shader
            #pragma fragment frag // Fragment shader

            fixed4 _Color;

            // Application to vertex shader: Vertex's information: position (clip space), normal (model space), and tex coord
            struct a2v {
                float4 vertex : POSITION; 
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0; // first texture coordinate input
            };

            struct v2f{
                float4 pos : SV_POSITION;
                fixed3 color : COLOR0;
                float4 texcoord : TEXCOORD0; 
            };
            
            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                o.texcoord = v.texcoord;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed3 c = i.color;
                
                c *= _Color.rgb;
                return fixed4(c, 1.0); // (0,0,0) = Black; (1,1,1) = White
                //return fixed4(i.texcoord * _Color);
            }

            ENDCG
        }
    }
}
// 冯乐乐著. Unity Shader入门精要 (p. 246). 人民邮电出版社. Kindle Edition. 