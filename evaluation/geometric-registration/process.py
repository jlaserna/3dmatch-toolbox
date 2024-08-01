import sys

def process_file(input_filename):
    try:
        # Abrir el archivo de entrada
        with open(input_filename, 'r') as file:
            lines = file.readlines()

        # Procesar las líneas
        processed_lines = []
        for i, line in enumerate(lines):
            elements = line.split()
            # Quitar el cuarto elemento de cada sexta línea (1, 7, 13, ...)
            if (i % 5 == 0) and len(elements) == 4:
                elements.pop(3)
            # Unir los elementos de nuevo en una línea
            processed_line = '\t'.join(elements)
            processed_lines.append(processed_line)

        # Crear el nombre del archivo de salida
        output_filename = f"_{input_filename}"

        # Guardar las líneas procesadas en un nuevo archivo
        with open(output_filename, 'w') as file:
            for processed_line in processed_lines:
                file.write(processed_line + '\n')

        print(f"Datos procesados y guardados en '{output_filename}'")

    except FileNotFoundError:
        print(f"El archivo '{input_filename}' no se encontró.")
    except Exception as e:
        print(f"Se produjo un error: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python script.py <nombre_del_archivo>")
    else:
        input_filename = sys.argv[1]
        process_file(input_filename)
