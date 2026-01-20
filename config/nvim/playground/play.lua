local subject =
  "jdt://contents/org.eclipse.jdt.ls.core_1.46.0.202503271314.jar/org.eclipse.jdt.ls.core.internal.managers/GradleUtils.class?=org.eclipse.jdt.ls.tests/%5C/home%5C/watage%5C/.local%5C/eclipse.jdt.ls%5C/plugins%5C/org.eclipse.jdt.ls.core_1.46.0.202503271314.jar%3Corg.eclipse.jdt.ls.core.internal.managers(GradleUtils.class"

local function string_starts(String, Start)
  return string.sub(String, 1, string.len(Start)) == Start
end

if string_starts(subject, "jdt://contents/") then
  print "true"
end

local index = string.find(subject, "/", string.len "jdt://contents/" + 1)
print(index)

if index ~= nil and index > 0 then
  print(string.sub(subject, 0, index))
end
