# choropleth map (コロプレスマップ, 階級区分図)

import sys
import pyodbc
import pandas as pd
import altair as alt
from altair_saver import save

con = pyodbc.connect(
    'Driver={IBM i Access ODBC Driver}; '
    'System=localhost; '
    'UID=ユーザーID; '
    'PWD=パスワード;'
    )

sql = "SELECT T2.pcode, COUNT(*) AS cnt "\
      "  FROM ライブラリー名.person T1 "\
      "    INNER JOIN ライブラリー名.prefcode T2 "\
      "      ON T1.PREF = T2.PNAME "

# https://vega.github.io/vega/docs/schemes/
colschema = sys.argv[1]

url = "https://raw.githubusercontent.com/dataofjapan/land/master/japan.topojson"
source = alt.topo_feature(url, "japan")

#All --------------------------------------------------------------
df = pd.read_sql(sql + "  GROUP BY T2.pcode ORDER BY T2.pcode", con)

mapA = alt.Chart(source).mark_geoshape(
        stroke='black',
        strokeWidth=1
).encode(
       alt.Color('CNT:Q', scale=alt.Scale(scheme=colschema),
		         legend=alt.Legend(title="人数")
				),
    tooltip=[alt.Tooltip('properties.nam_ja:N', title="都道府県"),
 			 alt.Tooltip('properties.id:Q', title="番号"),
 			 alt.Tooltip('CNT:Q', title="人数")]
).transform_lookup(
    lookup='properties.id',
    from_=alt.LookupData(df, 'PCODE', ['CNT'])
#).configure_legend(
#    gradientLength=400,
#    gradientThickness=30
#).configure_title(
#	fontSize=32
).properties(
    title='登録者都道府県別分布（全データ）',
#    width=400,
#    height=300
)

#M --------------------------------------------------------------
df = pd.read_sql(sql + 
	" WHERE T1.gender = 'M' GROUP BY T2.pcode ORDER BY T2.pcode", con)

mapM = alt.Chart(source).mark_geoshape(
        stroke='black',
        strokeWidth=1
).encode(
       alt.Color('CNT:Q', scale=alt.Scale(scheme=colschema),
		         legend=alt.Legend(title="人数")
				),
    tooltip=[alt.Tooltip('properties.nam_ja:N', title="都道府県"),
 			 alt.Tooltip('properties.id:Q', title="番号"),
 			 alt.Tooltip('CNT:Q', title="人数")]
).transform_lookup(
    lookup='properties.id',
    from_=alt.LookupData(df, 'PCODE', ['CNT'])
#).configure_legend(
#    gradientLength=400,
#    gradientThickness=30
#).configure_title(
#	fontSize=32
).properties(
    title='登録者都道府県別分布（男性）',
#    width=400,
#    height=300
)

#F --------------------------------------------------------------
df = pd.read_sql(sql + 
	" WHERE T1.gender = 'F' GROUP BY T2.pcode ORDER BY T2.pcode", con)

mapF = alt.Chart(source).mark_geoshape(
        stroke='black',
        strokeWidth=1
).encode(
       alt.Color('CNT:Q', scale=alt.Scale(scheme=colschema),
		         legend=alt.Legend(title="人数")
				),
    tooltip=[alt.Tooltip('properties.nam_ja:N', title="都道府県"),
 			 alt.Tooltip('properties.id:Q', title="番号"),
 			 alt.Tooltip('CNT:Q', title="人数")]
).transform_lookup(
    lookup='properties.id',
    from_=alt.LookupData(df, 'PCODE', ['CNT'])
#).configure_legend(
#    gradientLength=400,
#    gradientThickness=30
#).configure_title(
#	fontSize=32
).properties(
    title='登録者都道府県別分布（女性）',
#    width=400,
#    height=300
)

#X --------------------------------------------------------------
df = pd.read_sql(sql + 
	" WHERE T1.gender = 'X' GROUP BY T2.pcode ORDER BY T2.pcode", con)

mapX = alt.Chart(source).mark_geoshape(
        stroke='black',
        strokeWidth=1
).encode(
       alt.Color('CNT:Q', scale=alt.Scale(scheme=colschema),
		         legend=alt.Legend(title="人数")
				),
    tooltip=[alt.Tooltip('properties.nam_ja:N', title="都道府県"),
 			 alt.Tooltip('properties.id:Q', title="番号"),
 			 alt.Tooltip('CNT:Q', title="人数")]
).transform_lookup(
    lookup='properties.id',
    from_=alt.LookupData(df, 'PCODE', ['CNT'])
#).configure_legend(
#    gradientLength=400,
#    gradientThickness=30
#).configure_title(
#	fontSize=32
).properties(
    title='登録者都道府県別分布（自由）',
#    width=400,
#    height=300
)

#save(mapA | mapM | mapF | mapX, "/tmp/map_altair_all.html")

map1 = alt.vconcat(mapA, mapM)
map2 = alt.vconcat(mapF, mapX)
save((map1 | map2).configure(background='#DDEEFF'), sys.argv[2])
