const express = require('express');
const path = require('path');

const app = express();
app.use(express.static(path.join(__dirname, '/public')));
// app.use(express.favicon(path.join(__dirname, 'public/favicon.ico')));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
const port = process.env.PORT || 8080;
app.listen(port, () => {console.log(`\nポート${port}でLISTEN開始。`)});

const odbc = require("odbc");

app.get('/', (req, res) => {
    console.log('「/」へのGET要求。')
    res.sendFile(path.join(__dirname + '/index.html'));
});

app.post('/api/fts/v1/search/ifs', (req, res) => {
    console.log(req.ip + 'から「/api/fts/v1/search/ifs」へのPOST要求。');
    console.log(req.body);
    odbc.connect('DSN=*LOCAL;CCSID=1208;', (err, conn) => {
        if (err) { throw err; }
        // https://developer.ibm.com/technologies/systems/articles/sql-json-publishing-functions/
        let stmt =  "SELECT * FROM (SELECT * FROM TABLE ( " +
                            "TSIFS.TS_IFS('TSIFS', JSON_VALUE('" +
                            JSON.stringify(req.body) +
                            "', 'lax $.search_word'))) " +
                            "ORDER BY SCORE DESC)";
        if (req.body.search_extended != '1'){
            stmt += " FETCH FIRST 10 ROWS ONLY";
        }
        console.log(stmt);
        conn.query(stmt, (err, result) => {
            if (err) { throw err; }
            console.log(result.length + "件が検索された。");
            // console.log(JSON.stringify(result));
            // console.log(result);
            res.json(JSON.stringify(result));
        })
    })
});

app.get('/api/fts/v1/search/spl', (req, res) => {
    console.log(req.ip + 'から「/api/fts/v1/search/spl」へのGET要求。');
    // QUERY_STRINGをJSON文字列に変換
    let qrystr_JSON = JSON.parse(Object.keys(req.query));
    console.log(JSON.stringify(qrystr_JSON));
    odbc.connect('DSN=*LOCAL;CCSID=1208;', (err, conn) => {
        if (err) { throw err; }
        let stmt =  "SELECT * FROM (SELECT * FROM TABLE ( " +
                            "TSOUTQ.TS_OUTQ('TSOUTQ', JSON_VALUE('" +
                            JSON.stringify(qrystr_JSON) +
                            "', 'lax $.search_word'))) " +
                            "ORDER BY SCORE DESC)";
        if (qrystr_JSON.search_extended != '1'){
            stmt += " FETCH FIRST 10 ROWS ONLY";
        }
        console.log(stmt);
        conn.query(stmt, (err, result) => {
            if (err) { throw err; }
            console.log(result.length + "件が検索された。");
            res.json(JSON.stringify(result));
        })
    })
});

app.get('/spl2txt', (req, res) => {
    console.log(req.ip + 'から「/spl2txt」へのGET要求。');
    console.log(JSON.stringify(req.query));
    odbc.connect('DSN=*LOCAL;CCSID=1208;', (err, conn) => {
        if (err) { throw err; }
        let stmt =  "SELECT * FROM TABLE(gurilib.SPOOLED_FILE_DATA_DBCS(" +
                        "JOB_NAME => '"            + req.query.spl_job + "', " +
                        "SPOOLED_FILE_NAME => '"   + req.query.spl_nam + "', " +
                        "SPOOLED_FILE_NUMBER => '" + req.query.spl_nbr + "')) " +
                        "ORDER BY ORDINAL_POSITION"
        console.log(stmt);
        conn.query(stmt, (err, result) => {
            if (err) { throw err; }
            let lines = result.length;
            console.log(lines + "レコードが読み取られた。");
            let html = '<pre>';
            for(var i = 0; i < lines; i++) {
                html += result[i].SPOOLED_DATA + '<br>';
            };
            html += '</pre>';
            res.send(html);
        })
    })
});

app.put('/api/fts/v1/update/ifs', (req, res) => {
    console.log('「/api/fts/v1/update/ifs」へのPUT要求。')
    odbc.connect('DSN=*LOCAL;CCSID=1208;', (err, conn) => {
        if (err) { throw err; }
        let stmt = "CALL TSIFS.UPDATE";
        console.log(stmt);
        conn.query(stmt, (err, result) => {
            if (err) { throw err; }
            console.log("IFSファイルへの索引更新要求が発行された。");
            res.json('{"updateifs" : "OK"}');
        })
    })
});

app.put('/api/fts/v1/update/spl', (req, res) => {
    console.log('「/api/fts/v1/update/spl」へのPUT要求。')
    odbc.connect('DSN=*LOCAL;CCSID=1208;', (err, conn) => {
        if (err) { throw err; }
        let stmt = "CALL TSOUTQ.UPDATE";
        console.log(stmt);
        conn.query(stmt, (err, result) => {
            if (err) { throw err; }
            console.log("スプールファイルの索引更新要求が発行された。");
            res.json('{"updatespl" : "OK"}');
        })
    })
});