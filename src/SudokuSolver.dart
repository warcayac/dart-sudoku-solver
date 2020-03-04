/* -----------------------------------------------------------
# SUDOKU SOLVER by using OOP with Dart 2.7.1 or later
#
# (C) 2020 William Arcaya Carpio, Perú
# Released under MIT License
# eMail: warcayac@gmail.com
#
# Published: Febrero 17, 2020
# OS tested: Ubuntu (linux)
# -----------------------------------------------------------*/

import 'package:quiver/iterables.dart';
import 'package:trotter/trotter.dart';
import 'package:ansicolor/ansicolor.dart';
import 'dart:io';

final _BOARD_RANGE = range(9);
final _BLOCK_RANGE = range(3);
final _VALID_DIGITS = range(1, 10).toList();
final _STARTING_COUNTER = { for (var i in zip([_VALID_DIGITS, List.filled(_VALID_DIGITS.length, 9)])) i[0]:i[1] };

bool areEqualLists(List list1, List list2) {
	bool result = false;
	bool listExists(List o) => o.isNotEmpty && o != null;
	if((list1.runtimeType == list2.runtimeType) && listExists(list1) && listExists(list2) && list1.length==list2.length) {
		for(int i; i < list1.length; i++) {
			result = list1[i] == list2[i];
			if(!result) break;
		}
	}
	return result;
}

bool areEqualMaps(Map map1, Map map2) {
	bool result = false;
	bool mapExists(Map o) => o.isNotEmpty && o != null;
	if((map1.runtimeType == map2.runtimeType) && mapExists(map1) && mapExists(map2) && map1.length==map2.length) {
		// Iterator<MapEntry> ime = map1.entries.iterator;
		// while (ime.moveNext()) {
		//     result = ime.current.value == map2[ime.current.key];
		//     if(!result) break;
		// }
		for(MapEntry me in map1.entries) {
			result = me.value == map2[me.key];
			if(!result) break;
		}
	}
	return result;
}

// #####################################################################################################
// #####################################################################################################

class Cell {
	static List<Cell> unique_candidates = [];
	List<int> _candidates;
	int __value;
	bool is_given;
	Sector _from_quadrant;
	Sector _from_row;
	Sector _from_column;
	Map<String,int> __posRC;
	/*-------------------------------------------------------------------------------*/
	Cell() {
		this._candidates = new List<int>.from(_VALID_DIGITS);
		this.__value = null;
		this.is_given = false;
		this._from_quadrant = this._from_row = this._from_column = null;
		this.__posRC = null;
	}
	/*-------------------------------------------------------------------------------*/
	String call() { // callable function ==> Cell()
		// https://stackoverflow.com/questions/54018071/how-to-call-print-with-colorful-text-to-android-studio-console-in-flutter
		if (this.__value != null) {
			final val = this.__value.toString();
			AnsiPen redPen = AnsiPen()..red(bold:true);
			return (!this.is_given) ? val : redPen(val);
		} else return "";
	}
	/*-------------------------------------------------------------------------------*/
	get value => this.__value;
	/*-------------------------------------------------------------------------------*/
	set value(int v) {
		this.__value = v;
		if (v != null) {
			this._remove_candidates_from_cell(List<int>.from(this._candidates));
			this.__propagate_candidate_removal_through_sectors(v);
		}
	}
	/*-------------------------------------------------------------------------------*/
	get pos => this.__posRC;
	/*-------------------------------------------------------------------------------*/
	set pos(List<int> v) {
		if (v.length == 2) {
			if (this.__posRC == null)
				this.__posRC = {'row':v[0], 'col':v[1]};
		} 
		else
			throw TypeError("Se esperaba una tupla de par de dígitos numéricos válidos.");
	}
	/*-------------------------------------------------------------------------------*/
	void _check_uniqueness() {
		if (this.value == null) {
			if(this._candidates.length <= 1) {
				if(this._candidates.length == 1) {
					if (!Cell.unique_candidates.contains(this)) 
						Cell.unique_candidates.add(this);
				} else 
					throw NoCandidatesError("Celda ${this.pos} se ha quedado sin valores candidatos");
			}
		}
	}
	/*-------------------------------------------------------------------------------*/
	void __propagate_candidate_removal_through_sectors(int value) {
		this._from_quadrant._remove_candidate_from_sector(value);
		this._from_row._remove_candidate_from_sector(value);
		this._from_column._remove_candidate_from_sector(value);
	}
	/*-------------------------------------------------------------------------------*/
	void _remove_candidates_from_cell(var values) {
		if(values is int)
			this._candidates.remove(values);
		else {
			if(values is List)
				this._candidates = this._candidates.toSet().difference(values.toSet()).toList();
			else
				throw TypeError("Tipo de dato no aceptado");
		}
		// update availability in sectors
		this._from_quadrant._update_availability_in_sector(values);
		this._from_row._update_availability_in_sector(values);
		this._from_column._update_availability_in_sector(values);
	}
}

// #####################################################################################################
// #####################################################################################################

abstract class Sector {
	Map<int,int> _available;
	List<Cell> cells;
	/*-------------------------------------------------------------------------------*/
	Sector() {
		this._available = new Map.from(_STARTING_COUNTER);
		this.cells = [];
	}
	/*-------------------------------------------------------------------------------*/
	void _remove_candidate_from_sector(int value, {List<Cell> avoid = null}) {
		// Assign value to "avoid" if "avoid" is null; otherwise, "avoid" stays the same
		avoid ??= [];
		if (!this._solved()) {
			for (Cell cell in this.cells.toSet().difference(avoid.toSet()).toList()) {
				if (cell._candidates.contains(value)) { // omite celdas con valores asignados
					cell._remove_candidates_from_cell(value);
					// if (cell._candidates.isEmpty)
					//     throw NoCandidadtesError("Celda ${cell.pos} se ha quedado sin valores candidatos");
					cell._check_uniqueness();
				}
			}
		}
	}
	/*-------------------------------------------------------------------------------*/
	void _update_availability_in_sector(var keys) {
		if(keys is List) 
			for(int k in keys) this._available[k]--;
		else {
			if(keys is int) this._available[keys]--;
			else throw TypeError("Tipo de dato no aceptado");
		}
	}
	/*-------------------------------------------------------------------------------*/
	bool _solved() => {0}.containsAll(this._available.values.toSet());
}

// #####################################################################################################
// #####################################################################################################

class Row extends Sector { Row():super(); }
class Column extends Sector { Column():super(); }
class Quadrant extends Sector { Quadrant():super(); }

// #####################################################################################################
// #####################################################################################################

abstract class SudokuSolverError implements Exception {
	String errorMsg;
	SudokuSolverError(this.errorMsg);
}

class NoCandidatesError extends SudokuSolverError { NoCandidatesError(String err):super(err); }
class InconsistentBoardError extends SudokuSolverError { InconsistentBoardError(String err):super(err); }
class TypeError extends SudokuSolverError { TypeError(String err):super(err); }
class FileNotFoundError extends SudokuSolverError { FileNotFoundError(String err):super(err); }

// #####################################################################################################
// #####################################################################################################

class SudokuBoard {
	List<List<Cell>> __cells;
	List<Quadrant> __quadrants;
	List<Row> __rows;
	List<Column> __columns;
	int __step;
	/*-------------------------------------------------------------------------------*/
	SudokuBoard() {
		this.__cells = [];
		this.__quadrants = [];
		this.__rows = [];
		this.__columns = [];
		this.__step = 0;     // incrementa en 1 por celda-solución encontrada
	}
	/*-------------------------------------------------------------------------------*/
	void __build_board() {
		List<T> vectorOf<T>(T creatorFunc()) => [for(int _ in _BOARD_RANGE) creatorFunc()];
		List<List<T>> matrixOf<T>(T creatorFunc()) => [for(int _ in _BOARD_RANGE) [for(int _ in _BOARD_RANGE) creatorFunc()]];
		// limpiar listas
		Cell.unique_candidates.clear();
		this.__columns.clear();
		this.__rows.clear();
		this.__quadrants.clear();
		this.__cells.clear();
		// inicializar valores
		this.__cells     = matrixOf(() => new Cell());
		this.__quadrants = vectorOf(() => new Quadrant());
		this.__rows      = vectorOf(() => new Row());
		this.__columns   = vectorOf(() => new Column());
		this.__link_cells_to_sectors();
	}
	/*-------------------------------------------------------------------------------*/
	bool __load_data(String sequence, {bool restoring=false}) {
		try {
			for(MapEntry<int,String> me in sequence.split('').asMap().entries) {
				int value = int.tryParse(me.value) ?? 0;
				if(value > 0) {
					Cell cell = this.__cells[me.key ~/ 9][me.key % 9];
					cell.value = value;
					if(!restoring) cell.is_given = true;
					// print("Cell[${me.key ~/ 9},${me.key % 9}] = ${me.value} ${'>'*20}");
					// this.__show_availability_per_sector();
				}
			}
			return true;
		} on SudokuSolverError catch (e) {
			print("[ERROR] Tablero inconsistente. ${e.errorMsg}");
			return false;
		}
	}
	/*-------------------------------------------------------------------------------*/
	void show_board(int boardN, bool can_show) {
		/// Método para visualizar el estado de un tablero Sudoku.
		/// 
		/// ARGS:
		/// - can_show	: (bool) permite la visualización de tablero.
		/// - boardN	: (int) número de tablero siendo procesado su solución.
		if(can_show) {
			print("${'*'*30} [ BOARD Nº $boardN: STEP ${this.__step} ] ${'*'*30}");
			for(int row in _BOARD_RANGE) {
				if((row > 0) && (row % 3 == 0)) print("───┼───┼───");
				String line = "";
				for(int col in _BOARD_RANGE) {
					if((col > 0) && (col % 3 == 0)) line += "|";
					Cell cell = this.__cells[row][col];
					line += cell.value != null ? cell() : "·";
				}
				print(line);
			}
		}
	}
	/*-------------------------------------------------------------------------------*/
	void __link_cells_to_sectors() {
		for(int r in _BOARD_RANGE) {
			for(int c in _BOARD_RANGE) {
				Quadrant quadrant = this.__quadrants[(r~/3)*3+(c~/3)];
				Cell cell = this.__cells[r][c];
				quadrant.cells.add(cell);
				cell._from_quadrant = quadrant;
				cell.pos = [r,c];
			}
		}

		for(int r in _BOARD_RANGE) {
			this.__rows[r].cells.addAll(this.__cells[r]);
			for(int c in _BOARD_RANGE) 
				this.__cells[r][c]._from_row = this.__rows[r];
		}

		for(int c in _BOARD_RANGE) {
			for(int r in _BOARD_RANGE) {
				this.__columns[c].cells.add(this.__cells[r][c]);
				this.__cells[r][c]._from_column = this.__columns[c];
			}
		}
	}
	/*-------------------------------------------------------------------------------*/
	bool __trace_single_frequency_values(int way, int show_by_step, bool showing, int boardN) {
		/// Método privado que ratrea candidatos de frecuencia por sección.
		/// 
		/// ARGS:
		/// - way		    : (int) modo de rastreo, por cuadrante/fila/columna.
		/// - showing	    : (bool) permite la visualización de tableros intermedios y final.
		/// - show_by_step	: (int) cada cuántos pasos/asignaciones se mostrará el estado del
		/// 	    tablero Sudoku siendo resuelto. Omitido si se un lote de tableros,
		/// 	    en tal caso sólo llega a mostrar el tablero final.
		/// - boardN	    : (int) número de tablero siendo procesado su solución.
		
		final Map<int,List> sectorRefs = { 0: ["Cuadrante", this.__quadrants], 
										1: ["Fila", this.__rows], 
										2: ["Columna", this.__columns] };
		bool change_exists = false;
		// Escanear a través de cada unidad (cuadrante/fila/columna) del sector seleccionado
		for(int i in _BOARD_RANGE) {
			Map<Cell,int> targets = {};
			Sector sector = sectorRefs[way][1][i];
			// en el presente sector, ¿hay candidatos de frecuencia única?
			if(sector._available.containsValue(1)) {
				// para cada candidato de frecuencia única...
				for(int unique in [for(MapEntry<int,int> me in sector._available.entries) if(me.value==1) me.key]) {
					// escanear celdas que componen el sector en curso
					for(int j in _BOARD_RANGE) {
						Cell cell = sector.cells[j];
						// ¿celda contiene candidato de frecuencia única?
						if(cell._candidates.contains(unique)) {
							if(!targets.containsKey(cell)) {
								targets[cell] = unique;
								break;	// salir del FOR en curso
							} else throw Exception("[${sectorRefs[way][0]}] Celda contiene más de un candidato único.");
						}
					}
				}
				// tratar celdas con candidatos de frecuencia única
				if(targets.isNotEmpty) {
					change_exists = true;
					// establecer únicos como solución para su celda origen
					for(MapEntry<Cell,int> me in targets.entries) {
						Cell cell = me.key;
						this.__step++;
						cell.value = me.value;
						this.show_board(boardN, showing && (show_by_step>0) && (this.__step % show_by_step == 0));
					}
				}
			}
		}
		return change_exists;
	}
	/*-------------------------------------------------------------------------------*/
	bool __apply_naked_hidden_twins_technique() {
		bool change_exists = false;
		for(int i in _BOARD_RANGE) { // por cada cuadrante
			// identificar celdas que contienen candidatos de frecuencia 2 en el cuandrante
			Quadrant quadrant = this.__quadrants[i];
			Map<int,int> old_counter = Map.from(quadrant._available);
			List<int> twos = [for(MapEntry<int,int> me in quadrant._available.entries) if(me.value==2) me.key];
			if(twos.isNotEmpty){
				// targets = Map.fromIterables(twos, List.generate(twos.length, (_) => []));
				Map<int,List<Cell>> targets = { for(int x in twos) x:[] };
				for(int j in _BOARD_RANGE) {    // por cada celda en el cuadrante
					Cell cell = quadrant.cells[j];
					List<int> shared = cell._candidates.toSet().intersection(twos.toSet()).toList();
					// recolectar celdas que contienen candidatos de frecuencia 2
					if(cell._candidates.isNotEmpty && shared.isNotEmpty) {
						for(int key in shared) 
							targets[key].add(cell);
					}
				}
				// si un candidato aparece 2 veces en un misma fila/columna,
				// eliminar ese candidato del resto de celdas de esa fila/columna
				for(MapEntry<int,List<Cell>> me in targets.entries) {
					List<Cell> cells = me.value;
					if(cells[0].pos['row'] == cells[1].pos['row']) {    // comparar filas
						cells[0]._from_row._remove_candidate_from_sector(me.key, avoid:cells);
					} else {
						if(cells[0].pos['col'] == cells[1].pos['col'])     // comparar columnas
							cells[0]._from_column._remove_candidate_from_sector(me.key, avoid:cells);
					}
				}
				// si dos pares de candidatos aparecen en las mismas dos celdas, 
				// eliminar resto de candidatos en ambas celdas
				if(twos.length > 1) {
					for(List<int> combo in Combinations(2, twos)()) {
						if(targets[combo[0]].toSet().difference(targets[combo[1]].toSet()).isEmpty) {
							Cell cell1 = targets[combo[0]][0],
								cell2 = targets[combo[0]][1];
							cell1._remove_candidates_from_cell(cell1._candidates.toSet().difference(combo.toSet()).toList());
							cell2._remove_candidates_from_cell(cell2._candidates.toSet().difference(combo.toSet()).toList());
						}
					}
				}
			}
			change_exists = change_exists || !areEqualMaps(old_counter, quadrant._available);
		}
		// this.__show_candidates();
		// this.__show_availability_per_sector();
		return change_exists;
	}
	/*-------------------------------------------------------------------------------*/
	void __restore_board_by_using_sequence(String sequence, int step) {
		// Reiniciar contadores de todas las secciones
		for(int i in _BOARD_RANGE) {
			this.__quadrants[i]._available = Map.from(_STARTING_COUNTER);
			this.__rows[i]._available = Map.from(_STARTING_COUNTER);
			this.__columns[i]._available = Map.from(_STARTING_COUNTER);
		}
		// Reiniciar candidatos de celdas y valores de celdas
		for(int r in _BOARD_RANGE) {
			for(int c in _BOARD_RANGE) {
				Cell cell = this.__cells[r][c];
				cell._candidates = List.from(_VALID_DIGITS);
				cell.value = null;
			}
		}
		// Cargar secuencia
		this.__load_data(sequence, restoring:true);
		this.__step = step;
		// Vaciar lista de candidatos únicos
		Cell.unique_candidates.clear();
	}
	/*-------------------------------------------------------------------------------*/
	void __make_decisions() {
		/*---------------------------------------------------------------*/
		Cell detect_starting_cell_to_make_decision() {
			// ¿cuál es la menor cantidad de candidatos que tiene una celda en el tablero presente?
			int min_base = 9;
			int shared, l;
			Cell cell;
			for(Quadrant quadrant in this.__quadrants) {
				// Identificar los candidatos con frecuencia 2 en el cuadrante
				List<int> twins = [for(MapEntry<int,int> me in quadrant._available.entries) if(me.value==2) me.key];
				shared = 0;
				for(cell in quadrant.cells) { // este "cell" es el mismo declarado al inicio de la función
					l = cell._candidates.length;
					if(1 < l && l < min_base) min_base = l;
					if(twins.length > 1 && l > 1) {
						shared = cell._candidates.toSet().intersection(twins.toSet()).length;
						if(shared==2 && l==2) break;
						shared = 0;
					}
				}
				if(shared==2 && l==2) break;
				cell = null;
			}
			// Si se encontró una celda bajo condiciones de paridad...
			if(shared==2 && l==2 && cell!=null) return cell;
			// caso contrario, retornar la celda con el mínimo de canditatos
			for(Quadrant quadrant in this.__quadrants) {
				for(cell in quadrant.cells)
					if(cell._candidates.length == min_base)
						return cell;
			}
			return null;
		}
		/*---------------------------------------------------------------*/
		bool make_a_decision_on_the_candidate(int option, int row, int col) {
			bool decision_was_right = true;
			this.__cells[row][col].value = option;
			// print("     Opción seleccionada: $option");
			try {
				this.__solve(false, 0, 0, recursive:true);
				// print("     Opción ${option}... Correcta");
			} catch (_) {
				// print("     Opción ${option}... Fallida");
				decision_was_right = false;
			} finally {
				return decision_was_right;
			}
		}
		/*---------------------------------------------------------------*/
		// Seleccionar la celda de donde se empezarán a tomar decisiones
		Cell cell = detect_starting_cell_to_make_decision();
		if(cell == null) throw InconsistentBoardError("No se encuentra un camino de solución al tablero.");
		// Obtener data necesaria para propósitos de restauración/decisión
		final BASE_BOARD_SEQ = this.get_current_sequence();
		final BASE_STEP = this.__step;
		final OPTIONS = List<int>.from(cell._candidates);
		int row = cell.pos['row'],
			col = cell.pos['col'];
		// this.show_board(0, true);
		// print("Tomando decisiones sobre los candidatos ${cell._candidates} de la celda ${cell.pos}");
		cell = null;
		// Probar cada opción para saber cuál conduce al tablero solución
		bool is_right;
		for(MapEntry<int,int> me in OPTIONS.asMap().entries) {
			if(me.key > 0) {
				// this.show_board(0, true);
				this.__restore_board_by_using_sequence(BASE_BOARD_SEQ, BASE_STEP);
			}
			is_right = make_a_decision_on_the_candidate(me.value, row, col);
			if(is_right) break;
		}
		if(!is_right)
			throw InconsistentBoardError("Candidatos $OPTIONS conducen a un tablero inconsistente.");
	}
	/*-------------------------------------------------------------------------------*/
	void __solve(bool showing, int show_by_step, int boardN, {bool recursive=false}) {
		/// Método privado que procesa la solución a un tablero Sudoku.
		/// 
		/// ARGS:
		/// - showing		: (bool) permite la visualización de tableros intermedios y final.
		/// - show_by_step	: (int) cada cuántos pasos/asignaciones se mostrará el estado del
		/// 		tablero Sudoku siendo resuelto. Omitido si se un lote de tableros,
		/// 		en tal caso sólo llega a mostrar el tablero final.
		/// - boardN		: (int) número de tablero siendo procesado su solución.
		/// - recursive		: (bool) indica si el proceso se ejecuta en modo recursivo.
		if(show_by_step<0) show_by_step = 0;
		if(!recursive) this.__step = 0;
		bool twins_applied = false;
		bool made_decision = false;
		while (true) {
			// Tratar candidatos únicos en celda
			while(Cell.unique_candidates.isNotEmpty) {
				Cell cell = Cell.unique_candidates.removeAt(0);
				if(cell._candidates.isNotEmpty) {
					this.__step++;
					cell.value = cell._candidates[0];
					this.show_board(boardN, showing && (show_by_step>0) && (this.__step%show_by_step==0));
				}
			}
			
			// Localizar candidatos únicos por cuadrante (0), fila (1), columna (2)
			bool rescan = true;
			while(rescan && Cell.unique_candidates.isEmpty) {
				rescan = false;
				for(int way in _BLOCK_RANGE)
					rescan = rescan || this.__trace_single_frequency_values(way, show_by_step, showing, boardN);
				if(rescan) twins_applied = false;
			}
			if(Cell.unique_candidates.isNotEmpty) continue;
			if(this.is_solved()) break;

			// Aquí se llega sin candidatos únicos ni candidatos de frecuencia única en todos los sectores
			// Aplicar técnica de pares gemelos (naked/hidden twins) por cuadrante
			if(!twins_applied) {
				rescan = true;
				int num_try = 0;
				while(rescan && Cell.unique_candidates.isEmpty) {
					num_try++;
					rescan = this.__apply_naked_hidden_twins_technique();
				}
				if(Cell.unique_candidates.isNotEmpty) continue;
				// si el tablero no tiene cambios en sus candidatos tras aplicar la técnica en su primer
				// intento, entonces se debe aplicar el proceso de prueba-error inmediatamente
				if(num_try==1) break;
				// ya que hubo cambios en los candidatos del tablero, hacer un nuevo chequeo en busca de
				// celdas-solución. Si tras el chequeo no hay cambio alguno en el tablero, ya no debería
				// ejecutarse esta técnica, y debería salirse del bucle presente.
				twins_applied = true;
			} else break;
		}

		// Iniciar proceso de prueba-error si el tablero no ha sido resuelto
		if(!this.is_solved()) {
			this.__make_decisions();
			made_decision = true;
		}
		// Mostrar tablero final
		if(!recursive)
			this.show_board(boardN, showing && (made_decision || !((show_by_step>0) && (this.__step%show_by_step==0))));
	}
	/*-------------------------------------------------------------------------------*/
	MapEntry<String,bool> __parse_sequence(String data) {
		// https://www.technologyreview.com/s/426554/mathematicians-solve-minimum-sudoku-problem
		final minimum_numbers_given = 17;
		final values_per_board = 81;
		final seq = data.replaceAllMapped(RegExp(r'\s+'), (match) => '');
		return MapEntry(seq, (seq.length==values_per_board) && (RegExp(r'[1-9]').allMatches(seq).length>=minimum_numbers_given));
	}
	/*-------------------------------------------------------------------------------*/
	bool is_solved() {
		for(int i in _BOARD_RANGE) {
			if(!this.__quadrants[i]._solved()) return false;
		}
		return true;
	}
	/*-------------------------------------------------------------------------------*/
	void solve_from(String source, {int show_by_step=0, bool show_boards=true, String sep="\n", String text=""}) {
		/// Método principal llamado para dar solución a tablero(s) Sudoku.
		/// 
		/// ARGS:
		/// - source	: (str) cadena de texto representando: (1) una secuencia fija de 81
		/// 		caracteres alfanuméricos, ó (2) la localización del archivo conteniendo
		/// 		secuencias de tableros Sudoku.
		/// - show_by_step	: (int) cada cuántos pasos/asignaciones se mostrará el estado del
		/// 		tablero Sudoku siendo resuelto. Omitido si se un lote de tableros, en tal
		/// 		caso sólo llega a mostrar el tablero final.
		/// - show_boards	: (bool) permite la visualización de tableros intermedios y final.
		/// - sep		: (str) separador entre secuencias, útil si 'source' es un archivo.
		/// - text		: (str) texto a agregar al sumario estadístico final.
		source ??= '';
		if(source.length > 0) {
			List<String> sequences = [];
			try {
				// Si no es una secuencia, es archivo, entonces extraer todas las secuencias
				if(!this.__parse_sequence(source).value) {
					// if(FileSystemEntity.typeSync(source) != FileSystemEntityType.notFound) {
					File datasource = File(source);
					if(datasource.existsSync()) 
						sequences = datasource.readAsStringSync().trim().split(sep);
					else
						throw FileNotFoundError("File not found.");
				} else sequences.add(source);
				// Si se procesa más de un tablero, no mostrar soluciones parciales
				if(sequences.length > 1) show_by_step = 0;
				// Resolver tableros
				int csolved = 0, cout = 0, cunsolved = 0;
				List<num> times = [];	// registros de tiempos en segundos
				// Extraer cada secuencia y resolverla, midiendo su tiempo de ejecución
				for(MapEntry<int,String> me in sequences.asMap().entries) {
					MapEntry<String,bool> seq = this.__parse_sequence(me.value);
					if(seq.value) {
						this.__build_board();
						if(this.__load_data(seq.key)) {
							if(show_boards) print(seq.key);
							this.show_board(me.key+1, show_boards && (show_by_step>0));
							Stopwatch timer = Stopwatch()..start();
							try {
								this.__solve(show_boards, show_by_step, me.key+1);
							} on SudokuSolverError catch (e) {
								this.show_board(me.key+1, show_boards && (show_by_step==0));
								print("[${e.runtimeType}] ${e.errorMsg}");
							} catch (e) {
								this.show_board(me.key+1, show_boards && (show_by_step==0));
								print(e);
							} finally {
								timer.stop();
							}
							num delta = timer.elapsedMicroseconds/1e6;
							if(show_boards) print("(${delta.toStringAsFixed(5)} seconds)\n");
							if(this.is_solved()) {
								csolved++;
								times.add(delta);
							} else cunsolved++;
						} else cout++;
					} else cout++;
				}
				// Mostrar sumario estadístico al finalizar todo el proceso
				final size = sequences.length;
				final generalSummary = "Excluded $cout, Unsolved $cunsolved, Solved $csolved of $size $text puzzles";
				if(times.isNotEmpty) {
					final total = times.reduce((a,b) => a+b);
					final max = times.reduce((a,b) => a>b ? a : b);
					print("$generalSummary (avg ${(total/size).toStringAsFixed(5)} secs (${(size/total).toStringAsFixed(0)} Hz), max ${max.toStringAsFixed(5)} secs)");
				} else print(generalSummary);
			} on SudokuSolverError catch (e) {
				print("[${e.runtimeType}] ${e.errorMsg}");
			} catch (e) {
				print(e);
			}
		}
	}
	/*-------------------------------------------------------------------------------*/
	String get_current_sequence() {
		String seq = '';
		for(int r in _BOARD_RANGE) {
			for(int c in _BOARD_RANGE) {
				int value = this.__cells[r][c].value;
				seq += [null,0].contains(value) ? "0" : value.toString();
			}
		}
		return seq;
	}
	/*-------------------------------------------------------------------------------*/
	void __check_links() {	// sólo para propósitos de verificación
		// Checking rows
		for(int x in _BOARD_RANGE) {
			bool flag = true;
			for(int y in _BOARD_RANGE) {
				Cell cell = this.__cells[x][y];
				Row row = this.__rows[x];
				flag = flag && identical(cell, row.cells[y]) && identical(cell._from_row, row);
			}
			print("Row ${x}... ${flag ? 'passed' : 'failed'}");
		}
		// Checking columns
		for(int x in _BOARD_RANGE) {
			bool flag = true;
			for(int y in _BOARD_RANGE) {
				Cell cell = this.__cells[y][x];
				Column col = this.__columns[x];
				flag = flag && identical(cell, col.cells[y]) && identical(cell._from_column, col);
			}
			print("Column ${x}... ${flag ? 'passed' : 'failed'}");
		}
		// Checking quadrants
		for(int i in _BLOCK_RANGE) {	// por filas de cuadrantes
			for(int j in _BLOCK_RANGE) {	// por columnas de cuadrantes
				bool flag = true;
				int k = 0;
				for(int x in range(0+i*3, 3+i*3)) {
					for(int y in range(0+j*3, 3+j*3)) {
						Cell cell = this.__cells[x][y];
						Quadrant quad = this.__quadrants[3*i+j];
						flag = flag && identical(cell, quad.cells[k]) && identical(cell._from_quadrant, quad);
						k++;
					}
				}
				print("Quadrant ${3*i+j}... ${flag ? 'passed' : 'failed'}");
			}
		}
	}
	/*-------------------------------------------------------------------------------*/
	void __show_candidates() {	// sólo para propósitos de verificación
		for(int r in _BOARD_RANGE) {
			print("="*30);
			for(int c in _BOARD_RANGE)
				print("[$r,$c] --> ${this.__cells[r][c]._candidates}");
		}
	}
	/*-------------------------------------------------------------------------------*/
	void __show_availability_per_sector() {	// sólo para propósitos de verificación
		// rows
		print("="*30);
		for(int i in _BOARD_RANGE) print("Row $i --> counter: ${this.__rows[i]._available}");
		// columns
		print("="*30);
		for(int i in _BOARD_RANGE) print("Column $i --> counter: ${this.__columns[i]._available}");
		// quadrants
		print("="*30);
		for(int i in _BOARD_RANGE) print("Quadrant $i --> counter: ${this.__quadrants[i]._available}");
	}
}

// #####################################################################################################
// #####################################################################################################

main(List<String> args) {
	SudokuBoard Puzzle = SudokuBoard();
	// Puzzle.solve_from("003020600900305001001806400008102900700000008006708200002609500800203009005010300", 
	// 	text:"easy", show_boards:true, show_by_step:5);
	// Puzzle.solve_from("_1______3______________46_7_9__________1_3____43___8_56__8___2___7_5_98___5_4_7__", 
	// 	text:"expert", show_boards:true, show_by_step:5);
	// Puzzle.solve_from("_7_25_4__8_____9_3_____3_7_7____4_2_1_______7_4_5____8_9_6_____4_1_____5__7_82_3_", 
	// 	text:"diabolical", show_boards:true, show_by_step:0);
	// Puzzle.solve_from(".....5.8....6.1.43..........1.5........1.6...3.......553.....61........4.........", 
	// 	text:"impossible", show_boards:true, show_by_step:0);  // no solucionable, sirve para tomar tiempo de esta conclusión
	// Puzzle.solve_from("093000600000501000000000000100400050000090300000000800421000000000730000500000000", 
	// 	text:"evil", show_boards:true, show_by_step:0);	// solucionable
	// Puzzle.solve_from("000700000100000000000430200000000006000509000000000418000081000002000050040000300", 
	// 	text:"evil", show_boards:true, show_by_step:0); // solucionable
	// Puzzle.solve_from("000000012000000003002300400001800005060070800000009000008500000900040500470006000", 
	// 	text:"Blonde Platine", show_boards:true, show_by_step:0); // solucionable
	// Puzzle.solve_from("000002750018090000000000000490000000030000008000700200000030009700000000500000080", 
	// 	text:"snake17", show_boards:true, show_by_step:0);	// solucionable
	// Puzzle.solve_from(".....6....59.....82....8....45........3........6..3.54...325..6..................", 
	// 	text:"hardest", show_boards:true, show_by_step:0);	// solucionable
	// Puzzle.solve_from("data/easy50.txt", text:"easy", show_boards:false, sep:"========");
	// Puzzle.solve_from("data/top95.txt", text:"hard", show_boards:false);
	// Puzzle.solve_from("data/hardest.txt", text:"hardest", show_boards:false);
	Puzzle.solve_from("data/hardest(2019).txt", text:"hardest (2019)", show_boards:false);
}

// References used:
// https://norvig.com/sudoku.html

// Sitios para Sudoku
// https://www.free-sudoku.com/sudoku.php?dchoix=evil
