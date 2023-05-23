function analyze_load(measures)
    print("Index: ")
    println(measures.idx[1].time + measures.idx[2].time)
    print("Total: ")
    println(measures.total)
    println("By Chunk: ")
    DataFrame(
        chunk = 1:length(measures.read),
        n = (i -> i.value.derivedf.value).(measures.insert),
        read = measures.read,
        insert = (i -> i.time).(measures.insert),
        clean = (i -> i.time).(measures.clean),
        derivedf = (i -> i.value.derivedf.time).(measures.insert),
        apps = (i -> i.value.apps.time).(measures.insert),
        npl = (i -> i.value.npl.time).(measures.insert),
        cit = (i -> i.value.cit.time).(measures.insert),
        class = (i -> i.value.class.time).(measures.insert),
        title = (i -> i.value.title.time).(measures.insert),
        abstr = (i -> i.value.abstr.time).(measures.insert),
        fullt = (i -> i.value.fullt.time).(measures.insert),
        claim = (i -> i.value.claim.time).(measures.insert),
        appli = (i -> i.value.appli.time).(measures.insert),
        inv = (i -> i.value.inv.time).(measures.insert),
        fam = (i -> i.value.fam.time).(measures.insert),
    ) |> println
end

function tune()
    global db = LensDB("db/db.db")
    get_connection(drop_index!, db)
    ignore_fulltext!(true)
    measures1 = load_jsonl!(db, "data/lens-export-long.jsonl", skip_on_error = true, rebuild_index = false)
    analyze_load(measures1)
    measures2 = load_jsonl!(db, "/data/JuliaPatents/pla.jsonl", skip_on_error = true, rebuild_index = false)
    analyze_load(measures2)
    @time get_connection(build_index!, db)
end
