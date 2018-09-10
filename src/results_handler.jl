
"Stores the csv with the measuments done by the master. If for this specific metric the workers do not take any part in measuring, 
time : the data itself to be saved (time in seconds)
file : the filename to be saved under src/results/file.csv
adds 'n_workers' lines with zeros to keep the "
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
"Adds a header to the specified single column csv"
function putheader(csv::String, header::String)
    f = open(EXECUTING_PATH*csv*".csv","a+")
    write(f,header*"\n")
    flush(f)
    close(f)
end


"Get the individual logs created by the workers and merge them into a single file

You only need to specify where these individual csv's are stored and the function merges them into a single file"
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


#Todo change this function to make it work with both system and statistics
"Gets a folder with the individual csv's (maxmim,global tests, histogram time) logs and creates the system.csv

It stores the final output on src/results/system.csv and also returns it as a DataFrame"
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
    
    elapsed_t = table[:elapsed_time]    
    delete!(table,:elapsed_time)
    table[:elapsed_time] = elapsed_t    


    output_file = "./results/"*resultsdir*"/system.csv"
    touch(output_file)
    CSV.write(output_file,table)
    info("Results stored in: "*output_file)

    return table
end
