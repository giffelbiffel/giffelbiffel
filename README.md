every 30 seconds:
    loop 5 times:
        spawn a zombie at location of a random player

on death of zombie:
    attacker is a player
    if victim is wearing any armor or victim is holding any tool:
        add 15 to attacker's balance
        send "&aYou received &b15 &amoney for killing a geared zombie!" to attacker
    else:
        add 10 to attacker's balance
        send "&aYou received &b10 &amoney for killing a zombie!" to attacker
