Shader "Custom/Chapter10-Refraction"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _RefractionColor ("Refraction Color", Color) = (1, 1, 1, 1)
        _RefractionAmount ("Refraction Amount", Range(0,1)) = 1
        _RefractRatio ("Refraction", Range(0.1, 1)) = 0.5
        _Cubemap ("Refraction Cubemap", Cube) = "_Skybox"{}   
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

            fixed4 _Color;
            fixed4 _RefractionColor;
            fixed _RefractionAmount;
            fixed _RefractRatio;
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
			    fixed3 worldRefr : TEXCOORD3;
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

                // Compute the refract dir in world space
                o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

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

                // Use the refract dir in world space to access the cubemap
                fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractionColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // Mix the diffuse color with the refracted color
                fixed3 color = ambient + lerp(diffuse, refraction, _RefractionAmount) * atten;

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
            fixed4 _RefractionColor;
            fixed _RefractionAmount;
            fixed _RefractRatio;
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
			    fixed3 worldRefr : TEXCOORD3;
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

                // Compute the refract dir in world space
                o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

                // Pass shadow coordinates to pixel shade
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldViewDir);

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

                // Use the refract dir in world space to access the cubemap
                fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractionColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // Mix the diffuse color with the refracted color
                fixed3 color = lerp(diffuse, refraction, _RefractionAmount) * atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
