Shader "Custom/Chapter10-Mirror"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
    }
    SubShader
    {
        Pass{
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma multi_compile_fwdbase
            
            #pragma vertex vert
            #pragma fragment frag

            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            
            struct a2v {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                
            };
            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
            };

            v2f vert (a2v v){
                v2f o;

                // Transform the vertex from object space to projection space
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;
                // Mirror needs to flip x
                o.uv.x = 1 - o.uv.x;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                return tex2D(_MainTex, i.uv);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
