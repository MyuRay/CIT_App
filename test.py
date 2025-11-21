import math as m
a, b, c = map(int, input().split())

print("入力：","a=" + str(a) + " b=" + str(b) + " c=" + str(c))

if m.pow(b,2) - 4*a*c < 0:
    print("解なし")
    exit()

x_plus = (-b + m.sqrt(m.pow(b,2) - 4*a*c)) / (2*a)
x_minus = (-b - m.sqrt(m.pow(b,2) - 4*a*c)) / (2*a)

if m.pow(b,2) - 4*a*c == 0:
    print(f"{a}x²+{b}x+{c}のxの解は{x_plus}")
else:
    print(f"{a}x²+{b}x+{c}のxの解は{x_plus},{x_minus}")
