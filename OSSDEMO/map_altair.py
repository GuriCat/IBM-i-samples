# choropleth map (コロプレスマップ, 階級区分図)

import sys
import pyodbc
import pandas as pd
import altair as alt
from altair_saver import save

# https://www.ibm.com/docs/en/i/7.4?topic=details-connection-string-keywords
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

if sys.argv[1] != "A":
    sql = sql + " WHERE T1.gender = '" + sys.argv[1] + "'"

sql = sql + "  GROUP BY T2.pcode ORDER BY T2.pcode"

#print(sql)

df = pd.read_sql(sql, con)
# Check dataframe contents
#df.to_csv("/tmp/dataframe.csv")
#df.drop('pref', axis=1)
#print(df)

# https://vega.github.io/vega/docs/schemes/
colschema = sys.argv[2]

if sys.argv[1] == "A":
   title_cond = '（全データ）'
if sys.argv[1] == "M":
   title_cond = '（男性）'
if sys.argv[1] == "F":
   title_cond = '（女性）'
if sys.argv[1] == "X":
   title_cond = '（自由）'

# https://github.com/dataofjapan/land
url = "https://raw.githubusercontent.com/dataofjapan/land/master/japan.topojson"

source = alt.topo_feature(url, "japan")

# シングルクォーテーション内は大文字小文字を区別する。
# odbcから戻されるときに列名は大文字になっている。
map = alt.Chart(source).mark_geoshape(
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
).configure_legend(
    gradientLength=400,
    gradientThickness=30
).configure(
	background='#DDEEFF'
).configure_title(
	fontSize=24
).properties(
    title='登録者都道府県別分布' + title_cond,
    width=800,
    height=600
)

save(map, sys.argv[3])
