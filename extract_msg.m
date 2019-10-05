function v2 = extract_msg(s1)

len = length(s1);
j = 5;
i=2;
v2 = zeros(len+1,1);
v2(1) = s1(1);
while i<=floor(len/2)+1
    v2(j) = s1(i);
    if s1(i+1)< 8.86577779189757e-10
        v2(j)=v2(j)*(-1);
    end
    j = j+4;
    i = i+2;
end