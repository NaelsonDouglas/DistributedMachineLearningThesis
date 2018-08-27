d = Dict()

@sync begin	
	for x=1:100			
		@async begin		    
			tic()
		    sleep(1)
		    d[x] = toc()
		end
		
	end
end

print(d)