local start
local t = {}
for i = 0, 1000 do
	t[i] = i
end
local t2 = {}
for i = 0, 1000 do
	t2["X"..i] = i
end

print("\nLoops test:")
start = os.clock()
for i = 1, 1000 do
	for k,v in pairs(t) do end
end
io.write(("pairs = %.2fms"):format((os.clock() - start)*1000))
start = os.clock()
for i = 1, 1000 do
	for k,v in ipairs(t) do	end
end
io.write((", ipairs = %.2fms"):format((os.clock() - start)*1000))
start = os.clock()
local tt
for i = 1, 1000 do
	for j = 1, #t do tt = t[j] end
end
io.write((", index = %.2fms\n"):format((os.clock() - start)*1000))


print("\nInside loop locals vs outsin loop locals.")
start = os.clock()
for i = 1, 1000000 do
	local test = i
	local test2 = test
end
print(("Local inside loop: %.2fms"):format((os.clock() - start)*1000))

start = os.clock()
local test, test2
for i = 1, 1000000 do
	test = i
	test2 = test
end
print(("Local outside loop: %.2fms"):format((os.clock() - start)*1000))


print("\nTable vs local.")
start = os.clock()
local t = { t = { x = 1 }}
for i = 1, 500000 do
	t.t.x = i
end
print(("Basic table loop: %.2fms"):format((os.clock() - start)*1000))

start = os.clock()
local t = { t = { x = 1 }}
local tt = t.t
for i = 1, 500000 do
	tt.x = i
end
print(("local table loop: %.2fms"):format((os.clock() - start)*1000))

print("\nString index vs numeric index.")
start = os.clock()
local t = { a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8, i = 9, j = 10}
for i = 1, 1000000 do
	t.e = 10
end
print(("string index: %.2fms"):format((os.clock() - start)*1000))
start = os.clock()
local t = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
local e = 5
for i = 1, 1000000 do
	t[e] = 10
end
print(("integer index: %.2fms"):format((os.clock() - start)*1000))
