

function mergelogs(logsdir::String;measurements_path="./measurements/executing/")
    logs = readdir(measurements_path*logsdir*"/")    
        
    logs = map(logs) do x
        measurements_path*logsdir*"/"*x
    end

    f = open(measurements_path*logsdir*".csv","a+")

    for l=1:length(logs)
        
        log_i = open(logs[l])
        write(f,readlines(log_i))

        if(l!=length(logs))
            write(f,"\n")            
        end
    end

    rm(measurements_path*logsdir;force=true,recursive=true)
    flush(f)
    close(f)
end

mergelogs("train_global_model")
mergelogs("calculate_maxmin")
mergelogs("train_local_model")

dest = "./measurements/"*Dates.format(Dates.now(), "yy-mm-dd-e-HH:MM:SS")
mv("./measurements/executing",dest)