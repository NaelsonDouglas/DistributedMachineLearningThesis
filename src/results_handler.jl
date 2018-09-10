
function store_masterlog(time, file::String,header,n_workers=0)
    putheader(file,header)

    f = open(EXECUTING_PATH*file*".csv","a+")       
    write(f,string(time))  

    if n_workers > 0
        write(f,"\n")
        for i=1:n_workers
            write(f,"0")
            if i!=n_workers
                write(f,"\n")
            end
        end
    end
    flush(f)
    close(f)
end

function putheader(csv::String, header::String)
    f = open(EXECUTING_PATH*csv*".csv","a+")
    write(f,header*"\n")
    flush(f)
    close(f)
end



function mergelogs(logsdir::String,EXECUTING_PATH::String=EXECUTING_PATH)
    logs = readdir(EXECUTING_PATH*logsdir*"/")    
        
    logs = map(logs) do x
        EXECUTING_PATH*logsdir*"/"*x
    end

    f = open(EXECUTING_PATH*logsdir*".csv","a+")

    
    
    for log_index=1:length(logs)      

        log_i = open(logs[log_index])
        lines = readlines(log_i)
        
        for l=1:length(lines)            
            write(f,lines[l])
            if log_index!=length(logs)
                write(f,"\n")
            end

        end                
    end

    rm(EXECUTING_PATH*logsdir;force=true,recursive=true)
    info(EXECUTING_PATH*logsdir*" deleted")
    flush(f)
    close(f)
    
end

function generatetable(resultsdir::String)
    logs = readdir("./results/"*resultsdir)
        
    logs = map(logs) do x
        "./results/"*resultsdir*"/"*x
    end
    table = DataFrame()
    for l in logs
        currenttable = CSV.read(l)
        rm(l)
        table = hcat(table,currenttable)
    end
    #Makes the column "elapsed_time" be the last column
    @show table
    elapsed_t = table[:elapsed_time]    
    delete!(table,:elapsed_time)
    table[:elapsed_time] = elapsed_t    


    output_file = "./results/"*resultsdir*"/system.csv"
    touch(output_file)
    CSV.write(output_file,table)
    info("Results stored in: "*output_file)

    return table
end
