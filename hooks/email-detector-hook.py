#!/usr/bin/env python3
"""
Hook simple pour détecter les emails dans les outputs Claude
Version minimale qui ne fait que passer le message
"""

import sys

def main():
    # Lire l'input depuis stdin
    input_data = sys.stdin.read()
    
    # Passer le message original sans modification
    # (important pour ne pas perturber Claude)
    print(input_data, end='')

if __name__ == "__main__":
    main()