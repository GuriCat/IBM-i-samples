import sys
import pyodbc
import pandas as pd
import folium

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
    sql = sql + "  WHERE T1.gender = '" + sys.argv[1] + "'"

sql = sql + "  GROUP BY T2.pcode ORDER BY T2.pcode"

#print(sql)

df = pd.read_sql(sql, con)
# Check dataframe contents
#df.to_csv("/tmp/dataframe.csv")
#df.drop('pref', axis=1)
#print(df)

# 地図の基準として兵庫県明石市を設定
japan_location = [35, 135]
m = folium.Map(location=japan_location, zoom_start=5)

# 使えるcolormapを増やすためスケール分割数をデフォルトの6から5に変更
myscale = (df['CNT'].quantile((0,0.25,0.5,0.75,1))).tolist()

# カラースキーム
# http://quabr.com:8182/57220510/how-to-use-colormap-in-python
colschema = sys.argv[2]

# geojson読み込み
geojson = r'/home/ユーザー/japan.geojson'

folium.Choropleth(geo_data=geojson, data=df,
               name='登録者都道府県別分布',
               columns=['PCODE', 'CNT'],
               key_on='feature.properties.id',
#               threshold_scale=[2.2, 2.3, 2.4, 2.5, 2.6, 2.7],
                threshold_scale=myscale,
               fill_color=colschema,
                    legend_name='人数',
                reset=True
).add_to(m)

tiles = ['stamenwatercolor','cartodbpositron','openstreetmap','stamenterrain']
for tile in tiles:
    folium.TileLayer(tile).add_to(m)
folium.LayerControl().add_to(m)

if sys.argv[1] == "A":
   title_cond = '（全データ）'
if sys.argv[1] == "M":
   title_cond = '（男性）'
if sys.argv[1] == "F":
   title_cond = '（女性）'
if sys.argv[1] == "X":
   title_cond = '（自由）'
title_html = '''
        <head><style> html { overflow-y: hidden; } </style></head>
        <h3 align="center" style="font-size:20px"><b>登録者都道府県別分布cond
        </b></h3>
        '''
title_html = title_html.replace('cond', title_cond, 1)
m.get_root().html.add_child(folium.Element(title_html))

# 地図をhtml形式で出力
m.save(outfile=sys.argv[3])
