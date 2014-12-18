; Variables globales

globals [numFugas posX posY numElem islaObstaculo dirViento dirVientoOpuesto petroleoDetectado posXPetrol posYPetrol pxF pyF fugaDibujada
  open ; the open list of patches
  closed ; the closed list of patches
  optimal-path ; the optimal path, list of patches from source to destination
  caminoCreado
  creandoCamino
  patchFuga 
  nuevosDescubrimientosPetrol ; lista que contiene las posiciones de nuevos vertidos descubiertos mientras se limpiaba otro
  ]

; Razas

breed [submarinos submarino]
breed [fugas fuga]
breed [manchas mancha]

; Definición de la variables de cada agente 

submarinos-own [
  posIniX
  posIniY
  posIniAreaX
  posIniAreaY
  maxX
  maxY
  minX
  minY
  busquedaIniciada
  limpiezaIniciada
  transporteIniciado
  evitarIsla
  movimientosEvitar  ; indica el numero de movimientos en una direccion opuesta al objetivo para evitar una isla
  numChoques ; indica el número de veces que choca una isla al ir a su zona de búsqueda
  buscandoFuga ; indica si esta en la fase de búsqueda de fuga
  cercaniaFuga
  cercaniaPetroleo
  paso
  irApetroleo
  idaVueltaBarco ; variable booleana que indica si el submarino esta en la tarea de llevar el petroleo y volver a la mancha
  manchaDetec ; variable que almacena la mancha que detecta al buscar petróleo
  parcheActual ; indica el parche donde esta el submarino para el recorrido en profundidad
  movEspiral ; indica si el submarino se esta moviendo en espiral o no
  gradosEspiral
]

fugas-own [
  posIniX
  posIniY
  fugaReparada
]


patches-own 
[ 
  parent-patch ; patch's predecessor
  f ; the value of knowledge plus heuristic cost function f()
  g ; the value of knowledge cost function g()
  h ; the value of heuristic cost function h()

]

; turtle variables used
turtles-own
[
  path ; the optimal path from source to destination
  current-path ; part of the path that is left to be traversed 
  current-path-vuelta
]


to cargar
  clear-all
  ask patches [set pcolor blue] 
  set-default-shape submarinos "robot_submarino"
  set-default-shape manchas "petrol"
  draw-walls
  
  set dirViento random 360
  set nuevosDescubrimientosPetrol []
  set numFugas 0
  set petroleoDetectado false
  set caminoCreado false
  set creandoCamino false
  set fugaDibujada false
  create-submarinos numeroSubmarinos [ inicializarSubmarinos ]          ;; place them randomly
  create-fugas 1 [ inicializarFuga ]
  
  let numFilas 2
  let numCol (numeroSubmarinos / 2)
  let gapX ((max-pxcor * 2) / numCol)
  let gapY ((max-pycor * 2) / numFilas)
  
  
  set posX (max-pxcor * -1)
  set posY max-pycor
  
  set numElem 1
  
  let primeraFila true
  ask submarinos [ 
    set busquedaIniciada false
    set irApetroleo false
    set idaVueltaBarco false
    set manchaDetec nobody
    set movEspiral false

    set paso 0
    set current-path []
    set current-path-vuelta []
    set evitarIsla false
    set movimientosEvitar 10
    set numChoques 0
    set buscandoFuga false
    set limpiezaIniciada false
    set transporteIniciado false
    set cercaniaFuga 100
    set cercaniaPetroleo 100
    set pcolor yellow
    ifelse ((posX = 0) and (posY = 0)) 
    [ set heading 135]
    [ facexy posX posY ]
    
    ifelse primeraFila = true 
    [
      set posIniAreaX int (posX + 1)  ; En posIniArea guardo los valores siempre
      set posIniAreaY int (posY - 1)
      set posIniX posIniAreaX   ; En posIni guardo los valores pero se van modificando según donde quiera ir
      set posIniY posIniAreaY
      
    ]
    [
      set posIniAreaX int (posX)  ; En posIniArea guardo los valores siempre
      set posIniAreaY int (posY)
      set posIniX posIniAreaX   ; En posIni guardo los valores pero se van modificando según donde quiera ir
      set posIniY posIniAreaY
    ]
 
    ; Fijamos los límites de cada área de submarino
    set minX (int posX) 
    set maxX (int (posX + gapX))
    set minY (int (posY - gapY))
    set maxY (int posY)  
      
    set posX (int (posX + gapX))
    set numElem (numElem + 1)
    if (numElem > numCol) [
        set primeraFila false
        set posY (0)
        set posX (max-pxcor * -1)
        set numElem (1)
    ]
  fd 0.5
  ]
  
  reset-ticks
end


to generarFuga
  ifelse count fugas <= 9
  [
      create-fugas 1 [ inicializarFuga ]
  ]
  [
    user-message( "Ya ha generado suficientes fugas. Espere a que se reparen para agregar más." )
  ]
end

; Dibuja las paredes de rojo
to draw-walls
  ; paredes iz y dcha
  ask patches with [abs pxcor = max-pxcor]
    [ set pcolor red ]
  ; paredes arriba y abajo
  ask patches with [abs pycor = max-pycor]
    [ set pcolor red]
end


to inicializarSubmarinos
  setxy 0 0
  set color yellow
  if pcolor = red       
    [ inicializarSubmarinos ]       
end


to inicializarFuga
  setxy round random-xcor round random-ycor 
  if xcor = 0 or ycor = 0 or pcolor = red ; para no generar fugas en las perpendiculares ni bordes
  [
    inicializarFuga
  ]
  set posIniX xcor
  set posIniY ycor
  set heading dirViento
  set hidden? true
  
  ifelse (count fugas-on neighbors >= 1) or (pcolor = red) or (pcolor = brown) or (count patches in-radius 5 with [pcolor = red] > 0)
  [
    inicializarFuga
  ]
  [
    ifelse count fugas > 1 
    [
      let fugaVecina false
      if count fugas in-radius 10 > 1
        [
          set fugaVecina true 
        ]
      ifelse (fugaVecina = true) 
        [
          inicializarFuga
        ]
        [
          set pcolor gray
          set fugaReparada false
          set numFugas (numFugas + 1)
        ]
      
      
    ]
    [
      set pcolor gray
      set fugaReparada false
      set numFugas (numFugas + 1)
    ]
    
  ]
end

; Este método se encarga de comprobar en cada iteración si hay petróleo cerca del submarino
to detectaPetroleo
  if petroleoDetectado = false 
  [
    if [pcolor] of patch-here != gray
    [
      if (count manchas-here = 1) or 
        ((count manchas in-cone 4 90 >= 1) and ([pcolor] of patch-ahead 1 != brown ) and ([pcolor] of patch-ahead 2 != brown ) and 
          ([pcolor] of patch-ahead 3 != brown ) and ([pcolor] of patch-ahead 4 != brown ))
        [
          ifelse (manchaDetec = nobody)
          [
            ifelse (count manchas-here = 1)
            [
              set manchaDetec manchas-here
              face manchaDetec
            ]
            [
              set manchaDetec one-of manchas in-cone 4 90
              face manchaDetec
            ]
            show "Mancha detectada"
            

            set movEspiral false
            
          ]
          [
            set movEspiral false
            face manchaDetec
            ifelse [pcolor] of manchaDetec = gray
            [
              ask manchaDetec [ fd 0.5 ]
              let px 0
              let py 0
              ask manchaDetec [
                set px xcor
                set py ycor
              ]
              
              set posIniX px
              set posIniY py
              facexy px py
              ask manchaDetec [ 
                set heading dirVientoOpuesto
                fd 0.5
                set heading dirViento
              ]
            ]
            [
              let px 0
              let py 0
              ask manchaDetec [
                set px xcor
                set py ycor
              ]
              
              
              set posIniX px
              set posIniY py
              facexy px py
            ]
            
            
            if (distancexy posIniX posIniY < 0.1)
            [  
              ask submarinos
              [
                set current-path [] 
                set path [] 
              ]
              set petroleoDetectado true
              
              set dirVientoOpuesto 0
              ifelse (dirViento >= 0) and (dirViento <= 180)
              [ set dirVientoOpuesto (dirViento + 180) ]
              [ set dirVientoOpuesto (dirViento - 180) ]
              set heading dirVientoOpuesto
              set posXPetrol xcor
              set posYPetrol ycor
              
              if (numFugas >= 1)
              [ 
                set buscandoFuga true
                
                
              ]   
            ]
           
            if ([pcolor] of patch-ahead 1 = red) or ([pcolor] of patch-ahead 1 = brown)
            [
               set manchaDetec nobody
            ]
            
          ]
          
        ]
      
    ]
    
  ]
end

; Este método es el que se llama en cada iteración de la simulación 
to go
  if (ticks = 50000)  ; al cabo de un tiempo se levantan los limites de cada submarino
  [
    ask submarinos [
      set maxX max-pxcor
      set maxY max-pycor
      set minX max-pxcor * -1
      set minY max-pycor * -1
    ]
    show "A partir de ahora, cada submarino puede explorar libremente el mapa."
    
  ]
  
  ask submarinos [ ; analizo cada submarino para ver que movimiento tengo que hacer
    ifelse dejar_rastro?             
      [ pd ]                        
      [ pu ]
     
    detectaPetroleo
     
    ; dependiendo del estado del submarino hago una cosa u otra
    ifelse petroleoDetectado = true ; si algún submarino detectó petróleo
    [
      ifelse buscandoFuga = true ; si ese submarino detectó el petróleo y ahora está buscando la fuga
      [
        let fugaEncontrada false
        let posXSubma xcor
        let posYSubma ycor
        
        if (count fugas in-radius 5 >= 1)[
          let fugaDetec one-of fugas-on neighbors
          if fugaDetec != nobody
          [
            let px 0
            let py 0
            ask fugaDetec [
              set px xcor
              set py ycor 
            ]
     
            ifelse (distancexy px py < 1)    
            [
              set patchFuga fugaDetec
              set buscandoFuga false
           
              set numFugas (numFugas - 1)
              ask fugaDetec
              [
                set fugaReparada true
                set pcolor green
              ]
              set limpiezaIniciada true
              set heading dirViento
              set numChoques 0
            ]
            [
              face fugaDetec
            ]
            
          ] 
          
        ]
        
        fd 0.1
      ]
      [  ; Si no es un submarino buscando la fuga
        ask submarinos [
          set manchaDetec nobody 
        ]
        ifelse limpiezaIniciada = true 
          [
            
            ifelse transporteIniciado = false [
              ifelse ([pcolor] of patch-ahead 1 = red) or (count other patches in-cone 1.5 180 with [pcolor = green] > 0) or ([pcolor] of patch-ahead 1 = brown)
                [  
                  set numChoques (numChoques + 1)
                  ifelse numChoques  < 3
                  [
                    ifelse heading = dirViento
                    [
                      set heading dirVientoOpuesto
                    ]
                    [
                      set heading dirViento
                    ]
                  ]
                  [
                    
                    ifelse all? submarinos [color = yellow]
                    [ 
                      
                      if is-fuga? patchFuga
                      [
                        ask patchFuga [ set pcolor blue  die ]
                      ]
                      
                      set petroleoDetectado false
                      set caminoCreado false
                      set creandoCamino false
                      ask submarinos [
                        set irApetroleo false
                        set limpiezaIniciada false 
                        set buscandoFuga false
                        set busquedaIniciada false
                        set posIniX posIniAreaX   ; En posIni guardo los valores pero se van modificando según donde quiera ir
                        set posIniY posIniAreaY
                      ]     
                      
                    ]
                    [
         
                      fd 0.1
                      ifelse heading = dirViento
                      [
                        set heading dirVientoOpuesto
                      ]
                      [
                        set heading dirViento
                      ]
                      if (count other patches in-cone 1.5 180 with [pcolor = green] > 0)
                      [
                        ifelse heading = dirViento
                        [
                          set heading dirVientoOpuesto
                        ]
                        [
                          set heading dirViento
                        ]
                      ]
                    ]
                    
                  ]
                ]
                [
                  
                  let tocoIsla false
                  if [pcolor] of patch-ahead 1 = brown
                  ; if so, reflect heading around x axis
                  [  set tocoIsla true   ]
                  
                  ifelse tocoIsla = true
                  [  
                    set limpiezaIniciada false
                  ]
                  [
                    let petroleos other manchas in-radius 2 with [color = black]
                    let numeroPetroleos count petroleos
                    if numeroPetroleos > 0
                    [
                      let cercano min-one-of petroleos [distance myself] 
                      ifelse (cercaniaPetroleo > distance cercano)
                      [
                        set cercaniaPetroleo distance cercano
                      ] 
                      [
                        ask cercano
                          [ 
                            die
                          ]
                        set color black
                        set transporteIniciado true
                        set cercaniaPetroleo 100
                      ] 
                    ] 
                    
                    
                    
                    fd 0.1
                  ]
                  
                  if numChoques > 10
                  [
                    
                  ]
                  
                  
                ]
            ]
            [
              ifelse movimiento_entre_dos_puntos = "Aleatorio"
              [
                irAbarco  
              ]
              [
                idaYvueltaBarcoA*
              ]      
            ]
            
          ]
          [
            irInicioLimpieza  ; el submarino va hacia el punto donde se inicia la limpieza      
          ]  
        
      ]
      
    ]  ; si ningún submarino ha detectado petróleo
    [
      ifelse busquedaIniciada = true 
        [
         
          if (ticks mod 1000 = 0) and (movEspiral = false) and (movimiento_espiral? = true)
          [
             set movEspiral true 
             set gradosEspiral 360
             set heading 0
        
          ]
          
          if (movEspiral = true)
          [
            if heading = 0
            [
              set gradosEspiral (gradosEspiral / 2)
            ]
            
            set heading (heading + gradosEspiral) 
        
          ]


          rebotarSubmarino
          
          
          let tocoIsla false
          if [pcolor] of patch-ahead 1 = brown
          [  
            set tocoIsla true   
            if (movEspiral = true)
            [
              set movEspiral false
            ]
          ]
          
          if tocoIsla = true [
            while [[pcolor] of patch-ahead 0.3 = brown] [
              set heading random 360
            ]
          ]
          
         
            fd 0.1
           
          
        ]
        [      
          iraPunto
        ]  
    ]  
    
  ] ; fin de ask submarinos
  
  if (ticks mod 200 = 0) ; cada 200 iteraciones se crean manchas que salen de las fugas
  [
    let fugasLista []
    set fugasLista lput patches with [pcolor = gray and pxcor != 0 and pycor != 0] fugasLista
    while [length fugasLista > 0]
    [
      let fugaN first fugasLista
      let px 0
      let py 0 
      ask fugaN [ 
        set px pxcor
        set py pycor     
      ]
      if ((px != 0) and (py != 0)) [
        create-manchas 1 [
          set color black
          set xcor px
          set ycor py 
          set heading dirViento
          
        ]
      ]
      
      set fugasLista remove-item 0 fugasLista
    ]  
        
      
  ]
  


  ask manchas [ ; muevo las machas
      ifelse pcolor = blue
      [
            ;set pcolor black 
            mueveMancha
      ] 
      [
            mueveMancha
      ]
    
  ]

  tick  ; aumenta el contador de iteración
end

; Método que calcula el camino entre dos puntos utilizando el algoritmo A* y lo guarda en la varible path del submarino que lo llamó
to caminoEntreDosPuntosA* [puntoX puntoY]
   set posX xcor
   set posY ycor
   set path busca-Camino one-of patches with [pxcor = round posX and pycor = round posY] one-of patches with [pxcor = puntoX and pycor = puntoY]
   set current-path path
end

; Método que realiza los movimientos de ida y vuelta al barco desde el derrame utilizando el algoritmo A*
to idaYvueltaBarcoA*
  ifelse irApetroleo = false   ; Si va del petroleo al barco
    [
      ifelse current-path = []
      [
        set posIniX 0
        set posIniY 0
        
        caminoEntreDosPuntosA* round posIniX round posIniY
        set current-path remove-item 0 current-path
        face first current-path
      ]
      [
        let casilla first current-path
        let px 0
        let py 0
        ask casilla [
          set px pxcor
          set py pycor 
        ]
        facexy px py
        if distancexy px py < 0.1
        [
          set current-path remove-item 0 current-path
        ]
        
        fd 0.1
        
        
        ;facexy 0 0
        if (distancexy posIniX posIniY < 0.1)
        [  
          set irApetroleo true
          set current-path []
          set numChoques 0
          set color yellow   

             
        ]
        
      ]
    ]
    [
      
      irInicioLimpieza
      
      if length current-path = 0
        [ 
          
          ifelse (count neighbors with [pcolor = green] = 1)
            [
              set heading dirViento
              set limpiezaIniciada true 
              set busquedaIniciada true
              set irApetroleo false
              
              set idaVueltaBarco false
              set numChoques 0 
              set transporteIniciado false
            ]
            [
              ifelse ((who mod 2) = 0) 
                [
                  set heading dirViento
                  set limpiezaIniciada true 
                  set busquedaIniciada true
                  set irApetroleo false
                  
                  set idaVueltaBarco false
                  
                  set numChoques 0 
                  set transporteIniciado false
                  
                ]
                [
                  set heading dirVientoOpuesto
                  
                  set limpiezaIniciada true 
                  set busquedaIniciada true
                  set irApetroleo false
                  
                  set idaVueltaBarco false
                  
                  set numChoques 0
                  set transporteIniciado false
                  if (count other patches in-cone 1.5 180 with [pcolor = green] > 0)
                  [
                    set heading dirViento
                  ]
                ]
              
            ]
          
        ]
      
    ]
  
end


; Método que permite ir a un submarino al barco de forma aleatoria
to irAbarco
  if evitarIsla = false 
    [ 
       set posIniX 0
       set posIniY 0
       facexy 0 0
    ]
    
    
    let tocoIsla false 
    if [pcolor] of patch-ahead 1 = brown
    ; if so, reflect heading around x axis
    [  set tocoIsla true   ]
    
    if tocoIsla = true 
    [
      while [[pcolor] of patch-ahead 0.3 = brown] [
        set heading random 360
      ]
      set numChoques (numChoques + 1)
      set evitarIsla true
      set movimientosEvitar (movimientosEvitar + 10)
    ]
    
    
    ifelse evitarIsla = true 
    [
      fd 0.1
      set movimientosEvitar (movimientosEvitar - 1)
      if movimientosEvitar = 0 
      [ 
        set evitarIsla false
        facexy posIniX posIniY
      ]
      
      if ([pcolor] of patch-ahead 1 = red) 
      [  
        set movimientosEvitar 10
        facexy posIniX posIniY
      ]
    ]
    [
      if ([pcolor] of patch-ahead 1 = red) 
      [  
        facexy posIniX posIniY
      ]
     
     
      fd 0.1 
    ]
    
     if ((round pxcor = round posIniX) and (round pycor = round posIniY)) 
     [  
         set limpiezaIniciada false  
         set color yellow      
     ]
end

; Método que permite a un submarino ir a un lugar donde se detectó un derrame
to irInicioLimpieza
  ifelse movimiento_entre_dos_puntos = "Aleatorio"
  [
    if evitarIsla = false 
    [ 
      set posIniX posXPetrol
      set posIniY posYPetrol
      facexy posXPetrol posYPetrol
    ]
    
    
    let tocoIsla false 
    if [pcolor] of patch-ahead 1 = brown
    ; if so, reflect heading around x axis
    [  set tocoIsla true   ]
    
    if tocoIsla = true 
    [
      while [[pcolor] of patch-ahead 0.3 = brown] [
        set heading random 360
      ]
      set numChoques (numChoques + 1)
      set evitarIsla true
      set movimientosEvitar (movimientosEvitar + 10)
    ]
    
    
    
    ifelse evitarIsla = true 
    [
      fd 0.1
      set movimientosEvitar (movimientosEvitar - 1)
      if movimientosEvitar = 0 
      [ 
        set evitarIsla false
        facexy posIniX posIniY
      ]
      
      if ([pcolor] of patch-ahead 1 = red) 
      [  
        set movimientosEvitar 10
        facexy posIniX posIniY
      ]
    ]
    [
      if ([pcolor] of patch-ahead 1 = red) 
      [  
        facexy posIniX posIniY
      ]
      
      
      fd 0.1 
    ]

    if (distancexy posIniX posIniY < 0.1)
      [  
        set limpiezaIniciada true 
        set numChoques 0
        set transporteIniciado false
        ifelse ((who mod 2) = 0) 
        [
          set heading dirViento
        ]
        [
          ifelse ([pcolor] of patch-here = green)
          [
            set heading dirViento
          ]
          [
            set heading dirVientoOpuesto
          ]
        ]                
      ]
  ]
  [  ; Si el movimiento es usando el algoritmo A*

    ifelse current-path = [] ; Si no hemos calculado el camino
    [
      set posIniX round posXPetrol
      set posIniY round posYPetrol
      
      
      ifelse irApetroleo = true ; si va del barco al petroleo
      [
        set current-path []
        let primeraIda false
        ask first path [
          if pxcor != round posXPetrol and pycor != round posYPetrol
          [
            set primeraIda true
          ]
        ]
        ifelse primeraIda = true
          [
            caminoEntreDosPuntosA* round posXPetrol round posYPetrol
            set current-path remove-item 0 current-path
            face first current-path
          ]
          [
            set current-path reverse path
            set current-path remove-item 0 current-path
            face first current-path
          ]
       
      ]
      [
        caminoEntreDosPuntosA* round posIniX round posIniY
        set current-path remove-item 0 current-path
        face first current-path
      ]
      
    ]
    [  ; Si ya tenemos el camino
      let casilla first current-path
      let px 0
      let py 0
      ask casilla [
        set px pxcor
        set py pycor 
      ]
      facexy px py
 
      if distancexy px py < 0.1
        [
          set current-path remove-item 0 current-path
        ]
      
      fd 0.1
      

      if (distancexy posIniX posIniY < 0.1)
        [  
          set current-path []
          set limpiezaIniciada true 
          set numChoques 0
          set transporteIniciado false
          ifelse ((who mod 2) = 0) 
          [
            set heading dirViento
          ]
          [
            set px round xcor
            set py round ycor
            ifelse (count patches with [pxcor = px and pycor = py and pcolor = green] = 1)
            [
              
              set heading dirViento
            ]
            [
              set heading dirVientoOpuesto
            ]
          ]   
        ]
      
    ]
    
  ]
  
end

; Método que mueve el submarino hasta su zona de limpieza
to iraPunto
  ifelse movimiento_entre_dos_puntos = "Aleatorio"
  [
    if evitarIsla = false 
    [ 
       set posIniX posIniAreaX
       set posIniY posIniAreaY
       facexy posIniAreaX posIniAreaY
    ]
    
    
    let tocoIsla false 
    if [pcolor] of patch-ahead 1 = brown
    ; if so, reflect heading around x axis
    [  set tocoIsla true   ]
    
    if tocoIsla = true 
    [
      while [[pcolor] of patch-ahead 0.3 = brown] [
        set heading random 360
      ]
      set numChoques (numChoques + 1)
      set evitarIsla true
      set movimientosEvitar (movimientosEvitar + 10)
    ]
    
    ifelse evitarIsla = true 
    [
      fd 0.1
      set movimientosEvitar (movimientosEvitar - 1)
      if movimientosEvitar = 0 
      [ 
        set evitarIsla false
        facexy posIniX posIniY
      ]
      
      if ([pcolor] of patch-ahead 1 = red) 
      [  
        set movimientosEvitar 10
        facexy posIniX posIniY
      ]
    ]
    [
      if ([pcolor] of patch-ahead 1 = red) 
      [  
        facexy posIniX posIniY
      ]
     
     
      fd 0.1 
    ]
    
     if ((round pxcor >= round minX) and (round pxcor <= round maxX) and (round pycor >= round minY) and (round pycor <= round maxY)) 
     [  
        set busquedaIniciada true  
        set numChoques 0        
     ]
  ]
  [ ; Si el movimiento es usando A*
    ifelse current-path = []
    [
      set posIniX posIniAreaX
      set posIniY posIniAreaY
      caminoEntreDosPuntosA* posIniX posIniY
      set current-path remove-item 0 current-path
    ]
    [
      if manchaDetec = nobody
      [
        let casilla first current-path
        let px 0
        let py 0
        ask casilla [
          set px pxcor
          set py pycor 
        ]
        facexy px py
        if distancexy px py < 0.1
        [
          set current-path remove-item 0 current-path
        ]
      ]
      
      fd 0.1
      
     if ((round pxcor >= round minX) and (round pxcor <= round maxX) and (round pycor >= round minY) and (round pycor <= round maxY)) 
        [  
          set busquedaIniciada true  
          set numChoques 0   
          set current-path []  
        ]
      
    ]
  ]
    
end


; Este método reorienta el submarino cuando llega a un obstáculo o límite de área
to rebotarSubmarino  ;; turtle procedure
    
  if manchaDetec = nobody 
  [ 
     if ([pxcor] of patch-ahead 1 > maxX) 
    [ 
      while [[pxcor] of patch-ahead 1 > maxX] [
         set heading random 360
      ] 
      
      if (movEspiral = true)
      [
        set movEspiral false
      ]
    ]
    
  if [pxcor] of patch-ahead 1 < minX
    [ 
      while [[pxcor] of patch-ahead 1 < minX] [
         set heading random 360
      ] 
      
      if (movEspiral = true)
      [
        set movEspiral false
      ]
    ]
    
  if [pycor] of patch-ahead 1 > maxY
    [
      while [[pycor] of patch-ahead 1 > maxY] [
         set heading random 360
      ] 
      
      if (movEspiral = true)
      [
        set movEspiral false
      ]
    ]
    
  if [pycor] of patch-ahead 1 < minY
    [ 
      while [[pycor] of patch-ahead 1 < minY] [
         set heading random 360
      ] 
      
      if (movEspiral = true)
      [
        set movEspiral false
      ]
    ]
  ]
  
  if [pcolor] of patch-ahead 1 = red
  [
      if (movEspiral = true)
      [
        set movEspiral false
      ]
  ]
  
  
  while [[pcolor] of patch-ahead 1 = red] [
    set heading random 360
  ]
  
end

; Este método mueve cada mancha por el mapa y la mata si llega a un obstáculo
to mueveMancha ;; turtle procedure

  let tocoBorde false
  if abs [pxcor] of patch-ahead 1 = max-pxcor
    ; if so, reflect heading around x axis
    [  set tocoBorde true  
       die
    ]

  if abs [pycor] of patch-ahead 1 = max-pycor
    [  
      set tocoBorde true          
      die
    ]
    
  if [pcolor] of patch-ahead 1 = brown
    [ 
       set tocoBorde true     
       die     
     ]
    

  if (tocoBorde = false) and (ticks mod 200 = 0)
  [
    fd 0.5   
  ]
    
end

; Método para dibujar obstáculos con el ratón
to dibujar_Isla
  if mouse-down?     
    [
      display
      ask patch mouse-xcor mouse-ycor
        [ set pcolor brown ]
    ]
  
end

; Método para dibujar fugas con el ratón
to dibujaFuga
  if mouse-down? and fugaDibujada = false  
    [
      create-fugas 1 [
          set xcor mouse-xcor
          set ycor mouse-ycor
          set posIniX xcor
          set posIniY ycor
          set hidden? true
          set heading dirViento
          set pcolor gray
          set fugaReparada false
        ]    
      set fugaDibujada true
      set numFugas (numFugas + 1)  
       display   
    ]
    
    if not mouse-down? 
    [
      set fugaDibujada false
    ]
end


; **************************************************
; Parte para el algoritmo A*
; *************************************************


to encuentraCaminoA*
    set posX xcor
    set posY ycor
    set path busca-Camino one-of patches with [pxcor = round posX and pycor = round posY] one-of patches with [pxcor = 0 and pycor = 0]
    set optimal-path path
    set current-path path
    set current-path-vuelta  reverse path  
    set caminoCreado true
   
    ;show optimal-path
    output-show (word "Shortest path length : " length optimal-path)
  
end


to-report busca-Camino [ source-patch destination-patch] 
   output-show (word "Buscando camino con el algoritmo A*")
  let search-done? false
  let search-path []
  let current-patch 0
  set open []
  set closed []  
  
  set open lput source-patch open
  
  ; loop until we reach the destination or the open list becomes empty
  while [ search-done? != true]
  [    
    ifelse length open != 0
    [
      ; sort the patches in open list in increasing order of their f() values
      set open sort-by [[f] of ?1 < [f] of ?2] open
      
      ; take the first patch in the open list
      ; as the current patch (which is currently being explored (n))
      ; and remove it from the open list
      set current-patch item 0 open 
      set open remove-item 0 open
      
      ; add the current patch to the closed list
      set closed lput current-patch closed
      
      ; explore the Von Neumann (left, right, top and bottom) neighbors of the current patch
      ask current-patch
      [         
        ; if any of the neighbors is the destination stop the search process
        ifelse any? neighbors with [ (pxcor = [ pxcor ] of destination-patch) and (pycor = [pycor] of destination-patch)]
        [
          set search-done? true
        ]
        [
          ; the neighbors should not be obstacles or already explored patches (part of the closed list)          
          ask neighbors with [ pcolor != brown and pcolor != red and (not member? self closed) and (self != parent-patch) ]     
          [
            ; the neighbors to be explored should also not be the source or 
            ; destination patches or already a part of the open list (unexplored patches list)
            if not member? self open and self != source-patch and self != destination-patch
            [
              ; add the eligible patch to the open list
              set open lput self open
              
              ; update the path finding variables of the eligible patch
              set parent-patch current-patch 
              set g [g] of parent-patch  + 1
              set h distance destination-patch
              set f (g + h)
            ]
          ]
        ]
        if self != source-patch
        [
          
        ]
      ]
    ]
    [
      ; if a path is not found (search is incomplete) and the open list is exhausted 
      ; display a user message and report an empty search path list.
      user-message( "A path from the source to the destination does not exist." )
      report []
    ]
  ]
  
  ; if a path is found (search completed) add the current patch 
  ; (node adjacent to the destination) to the search path.
  set search-path lput current-patch search-path
  
  ; trace the search path from the current patch 
  ; all the way to the source patch using the parent patch
  ; variable which was set during the search for every patch that was explored
  let temp first search-path
  while [ temp != source-patch ]
  [
    ask temp
    [
     
    ]
    set search-path lput [parent-patch] of temp search-path 
    set temp [parent-patch] of temp
  ]
  
  ; add the destination patch to the front of the search path
  set search-path fput destination-patch search-path
  
  ; reverse the search path so that it starts from a patch adjacent to the
  ; source patch and ends at the destination patch
  set search-path reverse search-path  

  ; report the search path
  output-show (word "Camino obtenido")
  report search-path

end

; make the turtle traverse (move through) the path all the way to the destination patch
to move
    while [length current-path != 0]
    [
      go-to-next-patch-in-current-path
    ]
    if length current-path = 0
    [
      facexy 0 0
      ifelse ((round xcor = 0) and (round ycor = 0)) 
      [  
          set limpiezaIniciada true 
          set numChoques 0
          set color yellow      
      ]
      [
        fd 0.1
      ]
      
    ]
    
end

to go-to-next-patch-in-current-path  
  face first current-path
  ifelse paso = 10
  [
    
    move-to first current-path
    set current-path remove-item 0 current-path
    set paso 0
  ]
  [
    fd 0.1
    set paso (paso + 1)
    display
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
240
10
860
551
30
25
10.0
1
10
1
1
1
0
0
0
1
-30
30
-25
25
1
1
1
ticks
50.0

BUTTON
18
18
88
52
Cargar
cargar
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
124
18
190
52
Iniciar
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
17
64
146
97
dejar_rastro?
dejar_rastro?
1
1
-1000

SLIDER
18
167
190
200
numeroSubmarinos
numeroSubmarinos
2
20
2
2
1
NIL
HORIZONTAL

BUTTON
35
225
135
260
Dibujar Islas
dibujar_Isla
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
37
322
198
355
Generar Fuga Aleatoria
generarFuga
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
36
273
138
306
Dibujar Fuga
dibujaFuga
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
25
389
220
434
movimiento_entre_dos_puntos
movimiento_entre_dos_puntos
"Aleatorio" "Algoritmo A*"
1

SWITCH
15
117
181
150
movimiento_espiral?
movimiento_espiral?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This demo shows how to make turtles bounce off the walls.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

petrol
false
14
Rectangle -13345367 true false 0 0 300 300
Line -16777216 true 0 30 45 15
Line -16777216 true 45 15 120 30
Line -16777216 true 120 30 180 45
Line -16777216 true 180 45 225 45
Line -16777216 true 225 45 165 60
Line -16777216 true 165 60 120 75
Line -16777216 true 120 75 30 60
Line -16777216 true 30 60 0 60
Line -16777216 true 300 30 270 45
Line -16777216 true 270 45 255 60
Line -16777216 true 255 60 300 60
Polygon -16777216 false true 15 120 90 90 136 95 210 75 270 90 300 120 270 150 195 165 150 150 60 150 30 135
Polygon -16777216 false true 63 134 166 135 230 142 270 120 210 105 116 120 88 122
Polygon -16777216 false true 22 45 84 53 144 49 50 31
Line -16777216 true 0 180 15 180
Line -16777216 true 15 180 105 195
Line -16777216 true 105 195 180 195
Line -16777216 true 225 210 165 225
Line -16777216 true 165 225 60 225
Line -16777216 true 60 225 0 210
Line -16777216 true 300 180 264 191
Line -16777216 true 255 225 300 210
Line -16777216 true 16 196 116 211
Line -16777216 true 180 300 105 285
Line -16777216 true 135 255 240 240
Line -16777216 true 240 240 300 255
Line -16777216 true 180 0 240 15
Line -16777216 true 240 15 300 0
Polygon -16777216 false true 150 270 225 300 300 285 228 264
Line -16777216 true 223 209 255 225
Line -16777216 true 179 196 227 183
Line -16777216 true 228 183 266 192
Rectangle -13345367 true false 0 0 300 315
Circle -16777216 true true 48 183 85
Circle -16777216 true true 198 123 85
Circle -16777216 true true 78 33 85
Circle -16777216 true true 56 56 67
Circle -16777216 true true 86 206 67
Circle -16777216 true true 180 135 60
Circle -16777216 true true 60 15 60
Circle -16777216 true true 99 189 42
Circle -16777216 true true 210 165 60
Circle -16777216 true true 206 101 67
Rectangle -16777216 true true 0 0 315 300

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

robot_submarino
true
4
Polygon -955883 true false 120 165 75 285 135 255 165 255 225 285 180 165
Polygon -1184463 true true 135 285 105 165 105 75 120 45 135 15 150 0 165 15 180 45 195 75 195 165 165 285
Rectangle -955883 true false 147 176 150 300
Polygon -955883 true false 120 45 180 45 165 15 150 0 135 15
Line -955883 false 105 105 135 120
Line -955883 false 135 120 165 120
Line -955883 false 165 120 195 105
Line -955883 false 105 135 135 150
Line -955883 false 135 150 165 150
Line -955883 false 165 150 195 135

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
setup
set leave-trace? true
go
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
