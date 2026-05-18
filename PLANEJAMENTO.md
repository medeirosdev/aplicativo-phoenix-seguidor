# Phoenix App - Planejamento Completo

Aplicativo Flutter para controle do robo Bia (PHX-1) via BLE.
Substitui o Serial Bluetooth Terminal com interface dedicada.

---

## 1. Visao Geral do Projeto

### Objetivo
Aplicativo cross-platform (Android + iOS) para configurar, controlar, debugar e
monitorar o robo Bia da equipe Phoenix Unicamp durante competicoes de seguidor de linha.

### Stack Tecnologico
| Componente | Tecnologia |
|---|---|
| Framework | Flutter 3.x |
| Linguagem | Dart |
| BLE | `flutter_reactive_ble` |
| State Management | `provider` ou `riverpod` |
| Graficos (telemetria) | `fl_chart` |
| Armazenamento local | `shared_preferences` |
| Tema/UI | Material Design 3 |

### Conexao BLE com a Bia
| Parametro | Valor |
|---|---|
| Device Name | `Bia PHX-1` |
| Service UUID | `ab0828b1-198e-4351-b779-901fa0e0371e` |
| Characteristic UUID | `4ac8a682-9736-4e5d-932b-e9b31405049c` |
| MTU | 517 bytes |
| Terminador | `\r` (carriage return) |
| Operacoes | READ, WRITE, NOTIFY |

---

## 2. Protocolo de Comandos BLE

Todos os comandos terminam com `\r`. Formato: `[TIPO][DADOS]\r`

### 2.1 Configuracao (prefixo `C`)
| Comando | Codigo | Descricao |
|---|---|---|
| Line Follower | `CLF\r` | Modo seguidor de linha |
| Line Chaser | `CLC\r` | Modo perseguidor de linha |
| Virtual Line | `CVL\r` | Modo linha virtual (Pure Pursuit) |
| Aceleracao OFF | `CA0\r` | Desabilita aceleracao |
| Aceleracao ON | `CA1\r` | Habilita aceleracao |
| ESC OFF | `CE0\r` | Desabilita ESC/ventoinha |
| ESC ON | `CE1\r` | Habilita ESC/ventoinha |
| Aplicar Config | `COK\r` | Confirma e vai pra calibracao |
| Teste | `CTS\r` | Modo de teste |

### 2.2 Debug (prefixo `D`)
| Comando | Codigo | Descricao |
|---|---|---|
| Battery | `DBT\r` | Debug de bateria |
| IR | `DIR\r` | Debug do controle IR |
| Frontal Sensors | `DFS\r` | Debug dos sensores frontais |
| Desligar | `DOF\r` | Desliga debug |

### 2.3 Calibracao (prefixo `K`)
| Comando | Codigo | Descricao |
|---|---|---|
| Manual | `KM0\r` | Calibracao manual (sem salvar) |
| Manual + EEPROM | `KME\r` | Calibracao manual salvando na EEPROM |
| Da EEPROM | `KEE\r` | Carrega calibracao da EEPROM |
| Iniciar | `KOK\r` | Comeca a calibracao |

### 2.4 Corrida (prefixo `S`)
| Comando | Codigo | Descricao |
|---|---|---|
| Start | `SST\r` | Inicia corrida |
| Stop | `SSP\r` | Parada de emergencia |

### 2.5 PID (prefixo `P`)
| Comando | Exemplo | Descricao |
|---|---|---|
| Kp | `PP,1.5\r` | Ganho proporcional |
| Kd | `PD,0.015\r` | Ganho derivativo |
| Velocidade | `PV,2.5\r` | Tensao base dos motores (V) |
| ESC Power | `PE,85\r` | Potencia do ESC |
| Aceleracao Step | `PA,0.5\r` | Incremento de aceleracao |
| Consultar | `PC\r` | Retorna parametros atuais |

### 2.6 Giroscopio (prefixo `G`)
| Comando | Codigo | Descricao |
|---|---|---|
| Calibrar | `GC\r` | Calibra giroscopio (2000 amostras) |
| Mapear | `GMAP\r` | Habilita mapeamento da pista |
| Dump Mapa | `GDUMP\r` | Exporta mapa como CSV via BLE |

### 2.7 Linha Virtual (prefixo `V`)
| Comando | Exemplo | Descricao |
|---|---|---|
| Look-ahead | `VL,0.12\r` | Distancia de look-ahead (metros) |
| Ganho | `VG,2.0\r` | Ganho de steering |
| Suavizar | `VS,10\r` | Moving average (tamanho da janela) |
| Speed Profile | `VP,2.0,1.0,50\r` | Perfil de vel. (max_v, min_v, threshold) |
| Drift Correction | `VD,1\r` | Liga/desliga correcao de drift |
| Consultar | `VC\r` | Mostra parametros atuais |

### 2.8 Telemetria (prefixo `T`)
| Comando | Codigo | Descricao |
|---|---|---|
| Posicao | `TP\r` | Envia dados de posicao gravados |

### 2.9 Marcadores (prefixo `M`)
| Comando | Codigo | Descricao |
|---|---|---|
| Contar | `MM\r` | Conta marcadores laterais |

---

## 3. Arquitetura do App

### 3.1 Estrutura de Pastas

```
app_phoenix/
├── lib/
│   ├── main.dart                       # Entry point
│   ├── app.dart                        # MaterialApp, tema, rotas
│   │
│   ├── core/
│   │   ├── ble/
│   │   │   ├── ble_service.dart        # Scan, connect, disconnect
│   │   │   ├── ble_protocol.dart       # Encode/decode comandos
│   │   │   └── ble_constants.dart      # UUIDs, nomes
│   │   ├── theme/
│   │   │   └── app_theme.dart          # Cores Phoenix, tipografia
│   │   └── constants.dart              # Constantes globais
│   │
│   ├── models/
│   │   ├── robot_state.dart            # Estado atual do robo
│   │   ├── pid_params.dart             # Parametros PID
│   │   ├── race_config.dart            # Configuracao de corrida
│   │   ├── telemetry_data.dart         # Dados de telemetria
│   │   └── track_point.dart            # Ponto do mapa (x, y, vel, curv)
│   │
│   ├── providers/
│   │   ├── ble_provider.dart           # Estado da conexao BLE
│   │   ├── robot_provider.dart         # Estado geral do robo
│   │   ├── terminal_provider.dart      # Historico do terminal
│   │   └── telemetry_provider.dart     # Dados de telemetria em tempo real
│   │
│   ├── screens/
│   │   ├── connection/
│   │   │   └── connection_screen.dart  # Scan + conectar
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart   # Tela principal pos-conexao
│   │   ├── control/
│   │   │   ├── config_screen.dart      # Modo, aceleracao, ESC
│   │   │   ├── calibration_screen.dart # Calibracao dos sensores
│   │   │   ├── race_screen.dart        # Start/Stop/Resume
│   │   │   └── pid_screen.dart         # Ajuste de PID com sliders
│   │   ├── virtual_line/
│   │   │   └── virtual_line_screen.dart # Parametros Pure Pursuit
│   │   ├── debug/
│   │   │   └── debug_screen.dart       # Filtros de debug
│   │   ├── terminal/
│   │   │   └── terminal_screen.dart    # Terminal raw (tipo Serial BT)
│   │   ├── telemetry/
│   │   │   └── telemetry_screen.dart   # Graficos e mapa da pista
│   │   └── settings/
│   │       └── settings_screen.dart    # Config do app
│   │
│   └── widgets/
│       ├── status_bar.dart             # Barra: bateria, conexao, estado
│       ├── command_button.dart         # Botao padrao de comando
│       ├── pid_slider.dart             # Slider com label e valor
│       ├── terminal_output.dart        # Widget de output do terminal
│       ├── battery_indicator.dart      # Indicador visual de bateria
│       ├── connection_badge.dart       # Badge conectado/desconectado
│       └── track_map_painter.dart      # Canvas para desenhar a pista
│
├── assets/
│   └── phoenix_logo.png                # Logo da equipe
│
├── android/                            # Projeto Android nativo
├── ios/                                # Projeto iOS nativo
├── pubspec.yaml                        # Dependencias
└── PLANEJAMENTO.md                     # Este arquivo
```

### 3.2 Diagrama de Navegacao

```
[Connection Screen]
        │
        ▼ (conectou)
[Dashboard] ──────────────────────────────────────
   │        │         │        │       │         │
   ▼        ▼         ▼        ▼       ▼         ▼
[Config] [Calib.] [Corrida] [PID] [V.Line] [Terminal]
                                                  │
                                              [Debug]
                                              [Telem.]
```

### 3.3 Fluxo de Uso (espelha a state machine do robo)

```
1. Abrir app → Scan BLE → Conectar na "Bia PHX-1"
2. Dashboard mostra status (bateria, estado, modo)
3. Configuracao: escolher modo (LF/LC/VL), aceleracao, ESC → COK
4. Calibracao: escolher tipo → KOK
5. Pre-corrida: ajustar PID se necessario
6. Corrida: SST para iniciar, SSP para parar
7. Pos-corrida: ver telemetria, ajustar, repetir
```

---

## 4. Detalhamento das Telas

### 4.1 Connection Screen
**Proposito**: Encontrar e conectar ao robo.

- Botao "Escanear" que lista dispositivos BLE proximos
- Filtra automaticamente por nome "Bia PHX-1" (destaca no topo)
- Indicador de sinal (RSSI)
- Botao "Conectar" ao lado de cada dispositivo
- Status: Escaneando / Conectando / Conectado / Erro
- Auto-reconnect se perder conexao
- Historico de dispositivos recentes (shared_preferences)

### 4.2 Dashboard Screen
**Proposito**: Visao geral e navegacao rapida.

Layout em grid/cards:
```
┌──────────────────────────────────┐
│  [Phoenix Logo]   Bia PHX-1     │
│  ● Conectado     🔋 11.8V       │
│  Estado: CONFIGURATION          │
├──────────────────────────────────┤
│                                  │
│  [Configurar]    [Calibrar]     │
│                                  │
│  [Corrida]       [PID]          │
│                                  │
│  [Linha Virtual] [Terminal]     │
│                                  │
│  [Debug]         [Telemetria]   │
│                                  │
├──────────────────────────────────┤
│  >> PARADA DE EMERGENCIA <<     │
└──────────────────────────────────┘
```

- Cards grandes com icones
- Barra superior com bateria + estado do robo
- Botao de emergencia (SSP) sempre visivel, cor vermelha
- Notificacoes recebidas do robo aparecem como snackbar

### 4.3 Config Screen
**Proposito**: Configurar modo de corrida antes da calibracao.

```
┌──────────────────────────────────┐
│  MODO DE CORRIDA                 │
│  ○ Line Follower  (CLF)         │
│  ○ Line Chaser    (CLC)         │
│  ○ Virtual Line   (CVL)         │
├──────────────────────────────────┤
│  ACELERACAO                      │
│  [OFF]  [ON]                    │
├──────────────────────────────────┤
│  ESC / VENTOINHA                 │
│  [OFF]  [ON]                    │
├──────────────────────────────────┤
│  [  APLICAR CONFIGURACAO  ]     │
│          (COK)                   │
└──────────────────────────────────┘
```

- Radio buttons para modo
- Toggle switches para aceleracao e ESC
- Botao "Aplicar" envia `COK\r` (muda robo pra CALIBRATION_STATE)
- Feedback visual: confirma o que foi enviado

### 4.4 Calibration Screen
**Proposito**: Calibrar sensores.

```
┌──────────────────────────────────┐
│  TIPO DE CALIBRACAO              │
│  ○ Manual           (KM0)       │
│  ○ Manual + EEPROM  (KME)       │
│  ○ Carregar EEPROM  (KEE)       │
├──────────────────────────────────┤
│  GIROSCOPIO                      │
│  [ Calibrar Giro ]  (GC)        │
├──────────────────────────────────┤
│  [ INICIAR CALIBRACAO ]  (KOK)  │
└──────────────────────────────────┘
```

- Instrucoes na tela ("Posicione o robo sobre a linha...")
- Feedback do robo aparece em tempo real
- Indicador de progresso durante calibracao

### 4.5 Race Screen
**Proposito**: Controle da corrida.

```
┌──────────────────────────────────┐
│        CONTROLE DE CORRIDA       │
│                                  │
│     ┌───────────────────┐        │
│     │                   │        │
│     │   ▶  INICIAR      │        │
│     │      (SST)        │        │
│     │                   │        │
│     └───────────────────┘        │
│                                  │
│     ┌───────────────────┐        │
│     │   ■  PARAR        │        │
│     │      (SSP)        │        │
│     └───────────────────┘        │
│                                  │
│  Modo: Line Follower             │
│  Velocidade: 1.5V                │
│  Distancia: --                   │
│  Tempo: --                       │
└──────────────────────────────────┘
```

- Botao START grande e verde
- Botao STOP grande e vermelho
- Informacoes da corrida em tempo real (se telemetria ativa)
- Haptic feedback nos botoes

### 4.6 PID Screen
**Proposito**: Ajuste fino de parametros PID.

```
┌──────────────────────────────────┐
│  AJUSTE PID                      │
│                                  │
│  Kp ────────────●──── 1.50      │
│       0.0              5.0      │
│                                  │
│  Kd ──────●─────────── 0.015    │
│       0.0              0.1      │
│                                  │
│  Velocidade ───●─────── 1.50 V  │
│       0.0              12.0     │
│                                  │
│  ESC Power ────────●─── 8.0 V   │
│       0.0              12.0     │
│                                  │
│  Accel Step ──●──────── 0.50    │
│       0.0              2.0      │
│                                  │
│  [Consultar Atual] (PC)         │
│  [Enviar Todos]                 │
├──────────────────────────────────┤
│  PRESETS                         │
│  [Follower] [Chaser] [Custom]   │
└──────────────────────────────────┘
```

- Sliders com valor numerico editavel (tap no numero para digitar)
- Envio individual (ao soltar o slider) ou em lote
- Presets: Follower (kP=1.5, kD=0.015), Chaser (kP=3.4, kD=0.034)
- Botao "Consultar" (PC) para ler valores atuais do robo
- Salvar presets customizados no celular

### 4.7 Virtual Line Screen
**Proposito**: Configuracao do modo Pure Pursuit.

```
┌──────────────────────────────────┐
│  LINHA VIRTUAL (Pure Pursuit)    │
│                                  │
│  Look-ahead ──●──── 0.12 m      │
│     0.05            0.30        │
│                                  │
│  Ganho ────────●─── 2.0         │
│     0.5              5.0        │
│                                  │
│  Drift Correction [ON] [OFF]    │
├──────────────────────────────────┤
│  MAPEAMENTO                      │
│  [Mapear Pista]  (GMAP)         │
│  [Exportar Mapa] (GDUMP)        │
├──────────────────────────────────┤
│  SUAVIZACAO                      │
│  Janela ──────●──── 10          │
│     1               50          │
│  [Aplicar]  (VS,10)             │
├──────────────────────────────────┤
│  PERFIL DE VELOCIDADE            │
│  Max V ───────●──── 2.0 V       │
│  Min V ───────●──── 1.0 V       │
│  Threshold ───●──── 50 dps      │
│  [Calcular]  (VP,2.0,1.0,50)   │
├──────────────────────────────────┤
│  [Consultar Parametros] (VC)    │
└──────────────────────────────────┘
```

### 4.8 Terminal Screen
**Proposito**: Terminal raw, identico ao Serial Bluetooth Terminal.

```
┌──────────────────────────────────┐
│  TERMINAL    [Limpar] [Pausar]  │
├──────────────────────────────────┤
│  > Conectado a Bia!             │
│  > Bluetooth iniciado!          │
│  > kP: 1.500                    │
│  > kD: 0.015                    │
│  > Velocidade: 1.5V             │
│  > Calibracao iniciada...       │
│  > Sensor[0]: min=120, max=3800 │
│  > Sensor[1]: min=115, max=3750 │
│  > ...                          │
│  >                              │
│  >                              │
│  >                              │
│  >                              │
├──────────────────────────────────┤
│  [________________] [Enviar]    │
│  ☐ Adicionar \r   ☐ Hex mode   │
└──────────────────────────────────┘
```

- Scroll automatico (com opcao de pausar)
- Campo de texto para enviar comandos raw
- Opcao de adicionar `\r` automaticamente
- Timestamp opcional em cada linha
- Copiar mensagens (long press)
- Exportar log como arquivo .txt
- Filtro de texto (busca)
- Cor diferente para enviado (azul) vs recebido (branco)
- Modo HEX para debug avancado

### 4.9 Debug Screen
**Proposito**: Filtros de debug organizados.

```
┌──────────────────────────────────┐
│  DEBUG                           │
│                                  │
│  [ Bateria ]  (DBT)             │
│  [ IR ]       (DIR)             │
│  [ Sensores ] (DFS)             │
│  [ Desligar ] (DOF)             │
│                                  │
│  ─── Output ──────────────────  │
│  > Battery: 11.82V (MEDIUM)     │
│  > Battery: 11.80V (MEDIUM)     │
│  > Sensor pos: 0.23             │
│  > ...                          │
│                                  │
└──────────────────────────────────┘
```

- Botoes de toggle (destaca qual debug esta ativo)
- Output filtrado embaixo (compartilha com terminal)
- Botao "Desligar tudo" sempre visivel

### 4.10 Telemetry Screen
**Proposito**: Visualizacao de dados da corrida.

```
┌──────────────────────────────────┐
│  TELEMETRIA                      │
│                                  │
│  [Solicitar Dados] (TP)         │
│                                  │
│  ┌─────────────────────────┐    │
│  │      MAPA DA PISTA      │    │
│  │    (canvas X,Y plot)    │    │
│  │         ╭──╮            │    │
│  │        ╱    ╲           │    │
│  │   ╭───╯      ╰───╮     │    │
│  │   ╰───────────────╯     │    │
│  └─────────────────────────┘    │
│                                  │
│  Distancia total: 12.45m        │
│  Velocidade max: 3.2V           │
│  Curvatura max: 450 dps         │
│                                  │
│  [Exportar CSV]                 │
└──────────────────────────────────┘
```

- Grafico da pista (X,Y) usando CustomPainter
- Gradiente de cor por velocidade ou curvatura
- Zoom e pan no mapa
- Estatisticas da volta
- Botao para exportar/compartilhar CSV

### 4.11 Settings Screen
**Proposito**: Configuracoes do app.

- Auto-reconnect (on/off)
- Adicionar `\r` automaticamente (on/off)
- Timestamp no terminal (on/off)
- Tema claro/escuro
- Tamanho da fonte do terminal
- Sobre / versao do app

---

## 5. Tema Visual

### 5.1 Paleta de Cores (Phoenix)
```
Primary:        #FF6B00  (laranja Phoenix)
Primary Dark:   #E05500
Secondary:      #1E1E1E  (cinza escuro)
Background:     #121212  (tema escuro)
Surface:        #1E1E1E
Error/Stop:     #FF1744  (vermelho)
Success/Start:  #00E676  (verde)
Warning:        #FFAB00  (amarelo)
Text Primary:   #FFFFFF
Text Secondary: #B0B0B0
BLE Connected:  #00E676
BLE Scanning:   #2196F3
BLE Error:      #FF1744
```

### 5.2 Tipografia
- Headers: Bold, 18-24pt
- Body: Regular, 14-16pt
- Terminal: Monospace (JetBrains Mono ou Fira Code), 12-14pt
- Botoes: Semi-bold, 14pt

### 5.3 Principios de UI
- Tema escuro por padrao (uso em competicoes com pouca luz)
- Botoes grandes (facil de acertar durante competicao)
- Feedback haptico em acoes criticas (Start, Stop)
- Confirmacao antes de acoes destrutivas (Stop de emergencia NAO pede confirmacao)
- Status do robo sempre visivel (barra superior persistente)

---

## 6. Servico BLE - Detalhamento Tecnico

### 6.1 BleService (ble_service.dart)
```
Responsabilidades:
- Scan de dispositivos BLE (filtro por nome ou UUID)
- Conectar/desconectar
- Descobrir servicos e caracteristicas
- Escrever comandos na characteristic
- Ouvir notificacoes (NOTIFY) da characteristic
- Reconexao automatica
- Gerenciar estado da conexao

Streams expostos:
- connectionState: Stream<BleConnectionState>
- receivedData: Stream<String>  (mensagens do robo)
- scanResults: Stream<List<DiscoveredDevice>>
```

### 6.2 BleProtocol (ble_protocol.dart)
```
Responsabilidades:
- Montar comandos (adicionar \r)
- Parsear respostas do robo
- Validar formato dos comandos
- Helper methods para cada tipo de comando:
    sendConfig(mode)
    sendCalibration(type)
    sendStartRace()
    sendStopRace()
    sendPidParam(param, value)
    sendVirtualLineParam(param, value)
    sendDebugFilter(type)
    requestTelemetry()
    requestPidParams()
    requestGyroCalibration()
    requestMapDump()
```

### 6.3 Tratamento de Erros BLE
```
- Timeout de conexao: 10 segundos
- Retry de conexao: 3 tentativas com backoff
- Erro GATT 133: reconectar automaticamente (comum no Android)
- Perda de conexao: notificar usuario + tentar reconectar
- MTU negotiation: solicitar 517, aceitar o que o device suportar
- Permissoes: solicitar Location (Android) e Bluetooth (iOS)
```

---

## 7. Plano de Implementacao

### Fase 1 - Fundacao (core + conexao)
- [ ] Criar projeto Flutter (`flutter create app_phoenix`)
- [ ] Configurar pubspec.yaml com dependencias
- [ ] Configurar permissoes Android (AndroidManifest.xml) e iOS (Info.plist)
- [ ] Implementar `BleService` (scan, connect, read, write, notify)
- [ ] Implementar `BleProtocol` (encode/decode de todos os comandos)
- [ ] Implementar `BleConstants` (UUIDs)
- [ ] Criar `BleProvider` (estado da conexao)
- [ ] Criar `ConnectionScreen` (scan + connect)
- [ ] Tema base (`AppTheme`)

### Fase 2 - Terminal + Debug
- [ ] Implementar `TerminalProvider` (historico, filtros)
- [ ] Criar `TerminalScreen` (input + output + scroll)
- [ ] Criar `DebugScreen` (botoes de filtro + output)
- [ ] Diferenciar mensagens enviadas/recebidas (cores)
- [ ] Funcao de limpar/pausar/exportar log

### Fase 3 - Controle Principal
- [ ] Criar `DashboardScreen` (grid de cards + status bar)
- [ ] Criar `ConfigScreen` (modo, aceleracao, ESC)
- [ ] Criar `CalibrationScreen` (tipo + giroscopio)
- [ ] Criar `RaceScreen` (start/stop com botoes grandes)
- [ ] Implementar `RobotProvider` (estado geral)
- [ ] Botao de emergencia global (SSP)

### Fase 4 - PID + Virtual Line
- [ ] Criar `PidScreen` (sliders + presets)
- [ ] Salvar presets customizados (shared_preferences)
- [ ] Criar `VirtualLineScreen` (parametros Pure Pursuit)
- [ ] Implementar envio individual e em lote

### Fase 5 - Telemetria + Mapa
- [ ] Implementar `TelemetryProvider` (parser de CSV do mapa)
- [ ] Criar `TelemetryScreen` (graficos)
- [ ] Implementar `TrackMapPainter` (canvas X,Y)
- [ ] Zoom/pan no mapa
- [ ] Exportar dados como CSV

### Fase 6 - Polish
- [ ] Settings screen
- [ ] Auto-reconnect robusto
- [ ] Haptic feedback
- [ ] Animacoes de transicao
- [ ] Icone e splash screen do app
- [ ] Testes em dispositivos reais (Android + iOS)
- [ ] Build de release

---

## 8. Dependencias (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_reactive_ble: ^5.3.1    # Comunicacao BLE
  provider: ^6.1.1                 # State management
  fl_chart: ^0.66.0                # Graficos de telemetria
  shared_preferences: ^2.2.2       # Armazenamento local
  permission_handler: ^11.3.0      # Permissoes (BLE, Location)
  google_fonts: ^6.1.0             # Fonte monospace pro terminal
  share_plus: ^7.2.1               # Compartilhar CSV/logs
  path_provider: ^2.1.2            # Diretorio para salvar arquivos
  vibration: ^2.0.0                # Haptic feedback

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

---

## 9. Permissoes Necessarias

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

### iOS (Info.plist)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Necessario para conectar ao robo Bia via BLE</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Necessario para conectar ao robo Bia via BLE</string>
```

---

## 10. Referencia Rapida - Estados do Robo

```
INITIALIZATION  →  CONFIGURATION  →  CALIBRATION  →  PRE_RACE
                                                         │
                   STOP  ←  BRAKE  ←  DECELERATING  ←  RACE
                    │
                    ├──→ PRE_RACE (nova corrida)
                    ├──→ CONFIGURATION (reconfigurar)
                    └──→ TESTINGS (modo teste)
```

### Mapeamento Estado → Tela do App
| Estado do Robo | Tela Recomendada |
|---|---|
| INITIALIZATION | Dashboard (aguardar) |
| CONFIGURATION | Config Screen |
| CALIBRATION | Calibration Screen |
| PRE_RACE | Race Screen (ajustar PID) |
| RACE | Race Screen (monitorar) |
| DECELERATING | Race Screen (aguardar) |
| BRAKE | Race Screen (parado) |
| STOP | Dashboard / Telemetry |
| TESTINGS | Debug Screen |

---

## 11. Parametros Default do Robo (referencia)

| Parametro | Line Follower | Line Chaser |
|---|---|---|
| kP | 1.5 | 3.4 |
| kI | 0.0 | 0.0 |
| kD | 0.015 | 0.034 |
| Velocidade base | 1.5V | 4.5V |
| ESC/Fan | 0V | 8.0V |
| Accel step | 0.5V | 1.0V |

| Parametro Virtual Line | Valor Default |
|---|---|
| Look-ahead | 0.12m |
| Ganho | 2.0 |
| Max correction | 2.0V |
| Wheel base | 0.08m |
| Drift gain | 0.02 |
| Smooth window | 2 |

| Hardware | Spec |
|---|---|
| Bateria max | 12.0V |
| Bateria low | 11.2V |
| PWM freq | 50 kHz |
| Sensores frontais | 15 |
| Encoder pulsos/rev | 2048 |
| Roda diametro | 25mm |
| Mapa resolucao | 2cm |
| Mapa max pontos | 2000 (~40m) |
