def id_to_code(id: int) -> str:
    """
    Converte um ID inteiro em um código de 5 dígitos (string),
    usando multiplicação por um primo e módulo.
    """
    PRIME = 7919
    MODULO = 100000
    return f"{(id * PRIME) % MODULO:05d}"

def code_to_id(code: str) -> int:
    """
    Recupera o ID original a partir de um código de 5 dígitos,
    usando o inverso modular do primo.
    """
    PRIME = 7919
    MODULO = 100000
    INV_PRIME = pow(PRIME, -1, MODULO)
    return (int(code) * INV_PRIME) % MODULO