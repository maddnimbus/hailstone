splitString = (text, delimiter) ->
	list = {}
	pos = 1
	if string.find("", delimiter, 1)
		error("delimiter matches empty string!")
	while true do
		first, last = string.find(text, delimiter, pos)
		if first
			table.insert(list, string.sub(text, pos, first-1))
			pos = last + 1
		else
			table.insert(list, string.sub(text, pos))
			break
	return list

trimStringEnding = (s) ->
	n = #s
	while n > 0 and s\find("^%s", n)
		n = n - 1
	return s\sub(1, n)

trimString = (s) ->
	return (s\gsub("^%s*(.-)%s*$", "%1"))

combineTables = (t1, t2) ->
	for key, value in pairs(t2)
		t1[key] = value
	return t1

combineArrays = (t1, t2) ->
	for i, value in ipairs(t2)
		table.insert(t1, value)
	return t1

shallowCopy = (object) ->
	objectType = type(object)
	if objectType != 'table' then return object

	copy = {}
	for key, value in pairs(object) do
		copy[key] = value
	return copy


return {
	:splitString, :trimStringEnding, :trimString, :combineTables, :combineArrays, :shallowCopy
}