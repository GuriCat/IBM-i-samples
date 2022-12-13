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

# Query into dataframe
cursor = con.cursor()

if sys.argv[1] == "A":
    sql = "SELECT * FROM ライブラリー名.person"
else:
    sql = "SELECT * FROM ライブラリー名.person WHERE GENDER = '" + sys.argv[1] + "'"
data = pd.read_sql(sql, con)

if sys.argv[1] == "A":
   title_cond = '（全データ）'
if sys.argv[1] == "M":
   title_cond = '（男性）'
if sys.argv[1] == "F":
   title_cond = '（女性）'
if sys.argv[1] == "X":
   title_cond = '（自由）'

colschema = sys.argv[2]

chart = alt.Chart(data).mark_bar().encode(
    x=alt.X('PREF:N', sort='-y', title='都道府県'),
    y=alt.Y('count(GENDER)', title='件数'),
    color=alt.Color('GENDER', legend=alt.Legend(title="性別"),
	      scale=alt.Scale(scheme=colschema)),
#    tooltip=['PREF', 'GENDER', 'count(GENDER)']
    tooltip=[alt.Tooltip('PREF', title="都道府県"),
 			 alt.Tooltip('GENDER', title="性別"),
 			 alt.Tooltip('count(GENDER)', title="人数")]
).properties(
    title="都道府県別登録者グラフ" + title_cond
).configure(
	background='#F0F0F0'
).configure_axis(
    labelFontSize=16,
    titleFontSize=20
).configure_title(     # 「properties」と「configure」の順番でfontSizeが無視される場合有り？
	fontSize=24,
#	color='blue'
)

save(chart, sys.argv[3])
