local unn = {
	"stupidity",
	"confusion",
	"dementia",
}
for i=1, tonumber(matches[2]) do
	send("curing predict "..unn[i],false)
	cecho("\n<red> + + <yellow>"..unn[i]:upper().."<red> + +")
	ataxia.afflictions[unn[i]] = true
end