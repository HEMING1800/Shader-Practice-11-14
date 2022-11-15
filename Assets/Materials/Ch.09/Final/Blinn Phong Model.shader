Shader "Custom/Blinn Phong Model"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {} // model's default normal information
        _BumpScale("Bump Scale", Float) = 1.0 // control the bumping
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
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
            sampler2D _MainTex;
            float4 _MainTex_ST; // ST means Scale and translation
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert (a2v v){
                v2f o;

                // Transform the vertex from object space to projection space
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                // Transform the vertex from object space to world space
                fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // Transform the normal from object space to world space
                float3 worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // Compute the matrix that transform directions from tangent space to world space
                // Put the world position in w component for optimization
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                // Pass shadow coordinates to pixel shade
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                // Get the light direction in world space
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                // Get the view direction in world space
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                // Get the half direction in world space
                fixed3 halfDir = normalize(lightDir + viewDir);

                // Get the normal in tangent space
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                // Transform the normal from tangent space to world space
                bump = normalize(half3(dot(i.TtoW0.xyz,bump), dot(i.TtoW1.xyz,bump), dot(i.TtoW2.xyz, bump)));

                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;

                // Get ambient term
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // Compute diffuse term
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump, lightDir));

                // Compute specular term
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);

                // UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }

        // Compute shadow
        Pass{
            Tags { "LightMode"="ForwardAdd" }

            Blend One One

            CGPROGRAM

            // Create the shadows in the additional pass
            #pragma multi_compile_fwdadd_fullshadows 
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; // ST means Scale and translation
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert (a2v v){
                v2f o;

                // Transform the vertex from object space to projection space
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                // Transform the vertex from object space to world space
                fixed3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // Transform the normal from object space to world space
                float3 worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // Compute the matrix that transform directions from tangent space to world space
                // Put the world position in w component for optimization
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                // Pass shadow coordinates to pixel shade
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                // Get the view direction in world space
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                // Get the half direction in world space
                fixed3 halfDir = normalize(lightDir + viewDir);

                // Get the normal in tangent space
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                // Transform the normal from tangent space to world space
                bump = normalize(half3(dot(i.TtoW0.xyz,bump), dot(i.TtoW1.xyz,bump), dot(i.TtoW2.xyz, bump)));

                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;

                // Compute diffuse term
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump, lightDir));

                // Compute specular term
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);

                // UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                return fixed4((diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }
    }
    Fallback "Specular"
}
