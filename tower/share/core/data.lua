
function loadcsvfile(filename,indexcol)
        local path = "../data/" .. filename
        local titles = {}
        local linenum = 1
        local datas = {}
		local val = ""
        for line in io.lines(path) do
                if linenum == 1 then
                    titles = string.split(line,",")
					
                    for i,title in ipairs(titles) do
                        titles[i] = string.gsub(titles[i], "\r", "")
						titles[i] = string.gsub(titles[i], "\n", "")
						
                    end
                else
                    local content = string.split(line,",")
                    local key = linenum - 1

                    if indexcol then
                        key = content[indexcol]
                    end

                    local newdata = {}
                    for i,v in ipairs(content) do
						val = v
						val = string.gsub(val, "\r", "")
						val = string.gsub(val, "\n", "")
                        newdata[titles[i]] = val
                    end

                    if datas[key] then
                        print("duplicate key find ",filename,"at index",index)
                    end

                    datas[key] = newdata
					
                end

                linenum = linenum + 1
        end
        return datas
end

