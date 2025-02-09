import sys
import os
import importlib.util

class MyPySystem:
    def __init__(self):
        self.modules_dir = os.path.join(os.path.dirname(__file__), "modules")
        sys.path.append(self.modules_dir)

    def execute_module(self, module_name, *args):
        try:
            # Importar el módulo dinámicamente
            spec = importlib.util.spec_from_file_location(
                module_name,
                os.path.join(self.modules_dir, f"{module_name}.py")
            )
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)

            # Ejecutar la función principal del módulo
            if hasattr(module, "main"):
                result = module.main(*args)
                return result
            else:
                return f"Error: Module '{module_name}' does not have a 'main' function."
        except Exception as e:
            return f"Error executing module '{module_name}': {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python mypy.py <module_name> [args...]")
        sys.exit(1)

    system = MyPySystem()
    module_name = sys.argv[1]
    args = sys.argv[2:]
    result = system.execute_module(module_name, *args)
    print(result)