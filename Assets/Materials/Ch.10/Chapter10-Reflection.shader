Shader "Custom/Chapter10-Reflection"
{
    Properties{
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _ReflectionColor ("Reflection Color", Color) = (1, 1, 1, 1)
        _ReflectionAmount ("Reflection Amount", Range(0,1)) = 1
        _Cubemap("Reflection Cubemap", Cube) = "_Skybox" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        Pass{
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma multi_compile_fwdbase
            
            #pragma vertex vert
            #pragma fragment frag

            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            fixed4 _ReflectionColor;
            fixed _ReflectionAmount;
            samplerCUBE _Cubemap;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
 				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefl : TEXCOORD3;
                fixed3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            v2f vert (a2v v){
                v2f o;

                // Transform the vertex from object space to projection space
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                // Compute the reflect dir in world space
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

                // Pass shadow coordinates to pixel shade
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                // Use the reflect dir in world space to access the cubemap
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectionColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // Mix the diffuse color with the reflected color
                fixed3 color = ambient + lerp(diffuse, reflection, _ReflectionAmount) * atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        // Compute shadow
        Pass{
            Tags {"LightMode" = "ForwardAdd"}
            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdbase_fullshadows
            
            #pragma vertex vert
            #pragma fragment frag

            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            fixed4 _ReflectionColor;
            fixed _ReflectionAmount;
            samplerCUBE _Cubemap;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
 				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefl : TEXCOORD3;
                fixed3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            v2f vert (a2v v){
                v2f o;

                // Transform the vertex from object space to projection space
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                // Compute the reflect dir in world space
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

                // Pass shadow coordinates to pixel shade
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                // Use the reflect dir in world space to access the cubemap
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectionColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // Mix the diffuse color with the reflected color
                fixed3 color = lerp(diffuse, reflection, _ReflectionAmount) * atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
    Fallback "Reflective/VertexLit"
}
