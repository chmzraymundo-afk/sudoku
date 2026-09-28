<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resolutor Profesional de Sudoku</title>
    <!-- Tailwind CSS for modern utility-first styling -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        brand: {
                            50: '#f0fdf4',
                            100: '#dcfce7',
                            500: '#22c55e',
                            600: '#16a34a',
                            700: '#15803d',
                        }
                    }
                }
            }
        }
    </script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
        body {
            font-family: 'Inter', sans-serif;
        }
        /* Custom thick borders for 3x3 subgrids */
        .grid-cell {
            caret-color: transparent;
        }
        .border-r-thick {
            border-right: 3px solid #1e293b !important;
        }
        .border-b-thick {
            border-bottom: 3px solid #1e293b !important;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }
        .animate-fade-in {
            animation: fadeIn 0.3s ease-out forwards;
        }
        @keyframes popIn {
            0% { transform: scale(0.8); }
            50% { transform: scale(1.1); }
            100% { transform: scale(1); }
        }
        .animate-pop {
            animation: popIn 0.2s ease-in-out;
        }
    </style>
</head>
<body class="bg-slate-900 text-slate-100 min-h-screen flex flex-col justify-between selection:bg-emerald-500 selection:text-white">

    <header class="w-full py-6 px-4 bg-slate-800/50 backdrop-blur border-b border-slate-700/50 shadow-md">
        <div class="max-w-4xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
            <div class="flex items-center gap-3">
                <div class="bg-emerald-600 p-2.5 rounded-xl shadow-lg shadow-emerald-900/30">
                    <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"></path>
                    </svg>
                </div>
                <div>
                    <h1 class="text-xl sm:text-2xl font-bold tracking-tight text-white">Resolutor de Sudoku</h1>
                    <p class="text-xs sm:text-sm text-slate-400">Algoritmo de Backtracking en Tiempo Real</p>
                </div>
            </div>
            <!-- Difficulty presets -->
            <div class="flex items-center gap-2 bg-slate-900/80 p-1.5 rounded-xl border border-slate-700">
                <span class="text-xs text-slate-400 font-medium px-2 hidden sm:inline">Nivel:</span>
                <button onclick="loadPreset('easy')" class="px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-800 hover:bg-emerald-600 hover:text-white transition-all text-slate-300">Fácil</button>
                <button onclick="loadPreset('medium')" class="px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-800 hover:bg-emerald-600 hover:text-white transition-all text-slate-300">Medio</button>
                <button onclick="loadPreset('hard')" class="px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-800 hover:bg-emerald-600 hover:text-white transition-all text-slate-300">Difícil</button>
            </div>
        </div>
    </header>

    <main class="flex-1 max-w-4xl mx-auto w-full p-4 sm:p-6 flex flex-col items-center justify-center">
        
        <!-- Status Notification Box -->
        <div id="status-box" class="w-full max-w-[450px] mb-4 p-3 rounded-xl bg-slate-800/80 border border-slate-700 text-center text-sm font-medium transition-all shadow-inner text-slate-300">
            Ingresa números o selecciona un nivel para comenzar.
        </div>

        <!-- The 9x9 Sudoku Grid Container -->
        <div class="bg-slate-800 p-2 sm:p-3 rounded-2xl shadow-2xl border border-slate-700 relative">
            <div id="sudoku-grid" class="grid grid-cols-9 gap-0 bg-slate-900 border-2 border-slate-700 rounded-lg overflow-hidden shadow-inner">
                <!-- Javascript will inject inputs here -->
            </div>
        </div>

        <!-- Action Control Buttons -->
        <div class="flex flex-wrap items-center justify-center gap-3 mt-6 w-full max-w-md">
            <button onclick="solveSudoku()" class="flex-1 min-w-[130px] bg-emerald-600 hover:bg-emerald-500 active:scale-95 text-white font-semibold py-3 px-4 rounded-xl shadow-lg shadow-emerald-900/40 transition-all flex items-center justify-center gap-2">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path><path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                Resolver
            </button>
            <button onclick="clearBoard()" class="flex-1 min-w-[130px] bg-slate-700 hover:bg-slate-600 active:scale-95 text-slate-200 font-semibold py-3 px-4 rounded-xl shadow-lg transition-all flex items-center justify-center gap-2">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                Limpiar
            </button>
        </div>
    </main>

    <footer class="w-full py-4 text-center text-xs text-slate-500 border-t border-slate-800">
        Desarrollado con HTML5, Tailwind CSS y JavaScript Vanilla • Algoritmo Optimizado
    </footer>

    <script>
        // Presets for quick loading
        const presets = {
            easy: [
                [5, 3, 0, 0, 7, 0, 0, 0, 0],
                [6, 0, 0, 1, 9, 5, 0, 0, 0],
                [0, 9, 8, 0, 0, 0, 0, 6, 0],
                [8, 0, 0, 0, 6, 0, 0, 0, 3],
                [4, 0, 0, 8, 0, 3, 0, 0, 1],
                [7, 0, 0, 0, 2, 0, 0, 0, 6],
                [0, 6, 0, 0, 0, 0, 2, 8, 0],
                [0, 0, 0, 4, 1, 9, 0, 0, 5],
                [0, 0, 0, 0, 8, 0, 0, 7, 9]
            ],
            medium: [
                [0, 2, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 6, 0, 0, 0, 0, 3],
                [0, 7, 4, 0, 8, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 3, 0, 0, 2],
                [0, 8, 0, 0, 4, 0, 0, 1, 0],
                [6, 0, 0, 5, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 1, 0, 7, 8, 0],
                [5, 0, 0, 0, 0, 9, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 4, 0]
            ],
            hard: [
                [0, 0, 0, 6, 0, 0, 4, 0, 0],
                [7, 0, 0, 0, 0, 3, 6, 0, 0],
                [0, 0, 0, 0, 9, 1, 0, 8, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 5, 0, 1, 8, 0, 0, 0, 3],
                [0, 0, 0, 3, 0, 6, 0, 4, 5],
                [0, 4, 0, 2, 0, 0, 0, 6, 0],
                [9, 0, 3, 0, 0, 0, 0, 0, 0],
                [0, 2, 0, 0, 0, 0, 1, 0, 0]
            ]
        };

        const gridElement = document.getElementById('sudoku-grid');
        const statusBox = document.getElementById('status-box');

        // Initialize the 9x9 grid in the DOM
        function createGrid() {
            gridElement.innerHTML = '';
            for (let r = 0; r < 9; r++) {
                for (let c = 0; c < 9; c++) {
                    const input = document.createElement('input');
                    input.type = 'text';
                    input.maxLength = 1;
                    input.id = `cell-${r}-${c}`;
                    input.className = `w-8 h-8 sm:w-11 sm:h-11 text-center font-bold text-base sm:text-lg bg-slate-900 text-slate-100 focus:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition-all grid-cell`;
                    
                    // Add thick borders for 3x3 box separation
                    if ((c + 1) % 3 === 0 && c !== 8) {
                        input.classList.add('border-r-thick');
                    } else {
                        input.classList.add('border-r', 'border-r-slate-800');
                    }

                    if ((r + 1) % 3 === 0 && r !== 8) {
                        input.classList.add('border-b-thick');
                    } else {
                        input.classList.add('border-b', 'border-b-slate-800');
                    }

                    // Input constraints & event handlers
                    input.addEventListener('input', (e) => {
                        const val = e.target.value;
                        if (!/^[1-9]$/.test(val)) {
                            e.target.value = '';
                        } else {
                            e.target.classList.add('text-emerald-400', 'animate-pop');
                            setTimeout(() => e.target.classList.remove('animate-pop'), 200);
                        }
                        validateBoardRealtime();
                    });

                    // Navigation support via arrow keys could be added, standard behavior works nicely
                    gridElement.appendChild(input);
                }
            }
        }

        // Read current grid matrix from DOM inputs
        function getBoardFromDOM() {
            let board = [];
            for (let r = 0; r < 9; r++) {
                let row = [];
                for (let c = 0; c < 9; c++) {
                    const val = document.getElementById(`cell-${r}-${c}`).value;
                    row.push(val === '' ? 0 : parseInt(val));
                }
                board.push(row);
            }
            return board;
        }

        // Set board values into DOM
        function setBoardToDOM(board, isSolution = false) {
            for (let r = 0; r < 9; r++) {
                for (let c = 0; c < 9; c++) {
                    const cell = document.getElementById(`cell-${r}-${c}`);
                    const val = board[r][c];
                    if (val !== 0) {
                        cell.value = val;
                        if (isSolution && cell.dataset.original !== 'true') {
                            cell.classList.add('text-emerald-400', 'bg-emerald-950/30');
                        } else {
                            cell.dataset.original = 'true';
                            cell.classList.add('text-slate-100', 'font-extrabold');
                        }
                    } else {
                        cell.value = '';
                        cell.classList.remove('text-emerald-400', 'bg-emerald-950/30', 'text-slate-100');
                        delete cell.dataset.original;
                    }
                }
            }
        }

        // Load preset puzzles
        function loadPreset(type) {
            clearBoard();
            const preset = presets[type];
            for (let r = 0; r < 9; r++) {
                for (let c = 0; c < 9; c++) {
                    const val = preset[r][c];
                    if (val !== 0) {
                        const cell = document.getElementById(`cell-${r}-${c}`);
                        cell.value = val;
                        cell.dataset.original = 'true';
                        cell.classList.add('text-slate-100', 'font-extrabold');
                    }
                }
            }
            updateStatus(`Nivel ${type === 'easy' ? 'Fácil' : type === 'medium' ? 'Medio' : 'Difícil'} cargado.`, 'info');
        }

        // Clear entire board
        function clearBoard() {
            for (let r = 0; r < 9; r++) {
                for (let c = 0; c < 9; c++) {
                    const cell = document.getElementById(`cell-${r}-${c}`);
                    cell.value = '';
                    cell.className = `w-8 h-8 sm:w-11 sm:h-11 text-center font-bold text-base sm:text-lg bg-slate-900 text-slate-100 focus:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition-all grid-cell`;
                    if ((c + 1) % 3 === 0 && c !== 8) cell.classList.add('border-r-thick');
                    else cell.classList.add('border-r', 'border-r-slate-800');
                    if ((r + 1) % 3 === 0 && r !== 8) cell.classList.add('border-b-thick');
                    else cell.classList.add('border-b', 'border-b-slate-800');
                    delete cell.dataset.original;
                }
            }
            updateStatus('Tablero limpio. Ingresa nuevos números.', 'info');
        }

        // Sudoku validation helper
        function isValid(board, row, col, num) {
            for (let i = 0; i < 9; i++) {
                if (board[row][i] === num && i !== col) return false;
                if (board[i][col] === num && i !== row) return false;
                let boxRow = 3 * Math.floor(row / 3) + Math.floor(i / 3);
                let boxCol = 3 * Math.floor(col / 3) + (i % 3);
                if (board[boxRow][boxCol] === num && (boxRow !== row || boxCol !== col)) return false;
            }
            return true;
        }

        // Check if initial board state has conflicts
        function hasConflicts(board) {
            for (let r = 0; r < 9; r++) {
                for (let c = 0; c < 9; c++) {
                    let val = board[r][c];
                    if (val !== 0) {
                        board[r][c] = 0;
                        if (!isValid(board, r, c, val)) {
                            board[r][c] = val;
                            return true;
                        }
                        board[r][c] = val;
                    }
                }
            }
            return false;
        }

        // Backtracking algorithm implementation
        function solve(board) {
            for (let r = 0; r < 9; r++) {
                for (let c = 0; c < 9; c++) {
                    if (board[r][c] === 0) {
                        for (let num = 1; num <= 9; num++) {
                            if (isValid(board, r, c, num)) {
                                board[r][c] = num;
                                if (solve(board)) return true;
                                board[r][c] = 0;
                            }
                        }
                        return false;
                    }
                }
            }
            return true;
        }

        // Realtime validation visual check
        function validateBoardRealtime() {
            let board = getBoardFromDOM();
            let hasError = false;
            for (let r = 0; r < 9; r++) {
                for (let c = 0; c < 9; c++) {
                    const cell = document.getElementById(`cell-${r}-${c}`);
                    let val = board[r][c];
                    if (val !== 0) {
                        board[r][c] = 0;
                        if (!isValid(board, r, c, val)) {
                            cell.classList.add('bg-rose-950/60', 'text-rose-400');
                            hasError = true;
                        } else {
                            cell.classList.remove('bg-rose-950/60', 'text-rose-400');
                        }
                        board[r][c] = val;
                    } else {
                        cell.classList.remove('bg-rose-950/60', 'text-rose-400');
                    }
                }
            }
            if (hasError) {
                updateStatus('¡Atención! Hay números duplicados en filas, columnas o bloques.', 'error');
            } else {
                updateStatus('Tablero en estado válido.', 'info');
            }
        }

        // Main solve trigger
        function solveSudoku() {
            let board = getBoardFromDOM();
            if (hasConflicts(board)) {
                updateStatus('El tablero actual contiene errores o conflictos imposibles de resolver.', 'error');
                return;
            }

            // Copy board to test resolution
            let boardCopy = board.map(row => [...row]);
            const startTime = performance.now();
            if (solve(boardCopy)) {
                const endTime = performance.now();
                setBoardToDOM(boardCopy, true);
                updateStatus(`¡Sudoku resuelto con éxito en ${(endTime - startTime).toFixed(2)} ms!`, 'success');
            } else {
                updateStatus('Este Sudoku no tiene solución válida.', 'error');
            }
        }

        // Update status bar messaging with colors
        function updateStatus(message, type) {
            statusBox.textContent = message;
            statusBox.className = "w-full max-w-[450px] mb-4 p-3 rounded-xl border text-center text-sm font-medium transition-all shadow-inner animate-fade-in ";
            if (type === 'error') {
                statusBox.classList.add('bg-rose-950/40', 'border-rose-800', 'text-rose-300');
            } else if (type === 'success') {
                statusBox.classList.add('bg-emerald-950/40', 'border-emerald-800', 'text-emerald-300');
            } else {
                statusBox.classList.add('bg-slate-800/80', 'border-slate-700', 'text-slate-300');
            }
        }

        // Initialize grid on load
        window.onload = function() {
            createGrid();
        };
    </script>
</body>
</html>
