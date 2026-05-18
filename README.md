# Phoenix App — Controle BLE do Robô Seguidor de Linha

Aplicativo Flutter para controle e monitoramento do robô **Bia (PHX-1)** da equipe Phoenix Unicamp via Bluetooth Low Energy (BLE).

---

## Funcionalidades

### Conexão BLE
- Scan e conexão com o robô via BLE
- Indicador de status de conexão em tempo real
- Reconexão automática

### Dashboard
- Visão geral do estado do robô
- Acesso rápido a todas as funções
- Indicadores de bateria, modo e estado da corrida

### Configuração
- Seleção de modo: **Line Follower**, **Line Chaser**, **Virtual Line**
- Ativar/desativar aceleração progressiva e ESC
- Envio de configuração via `COK`

### PID
- Ajuste de **Kp**, **Kd**, **velocidade base**, **potência ESC** e **passo de aceleração**
- Sliders com envio BLE em tempo real
- Consulta de parâmetros atuais via `PC`

### Calibração
- Calibração manual dos sensores de linha (`KM0`, `KME`, `KEE`)
- Calibração do giroscópio (`GC`)
- Confirmação de calibração (`KOK`)

### Corrida
- Botões **START** (`SST`) e **STOP** (`SSP`)
- Monitoramento do estado da corrida

### Linha Virtual (Pure Pursuit)
- Ajuste de **look-ahead** (`VL`) e **ganho** (`VG`)
- Controle de **drift correction** (`VD`)
- Configuração de **blend** linha física / Pure Pursuit (`VB`, `VK`)
- **Resolução do mapeamento** (`VM`)
- **Suavização** da trajetória (`VS`)
- **Speed Profile** automático (`VP`)
- Consultar parâmetros via `VC`

### Telemetria
- Gráfico em tempo real de distância, yaw e GiroZ
- Recebimento de dados a 10Hz via BLE

### Terminal
- Terminal BLE raw para envio de comandos manuais
- Log de mensagens recebidas do robô

### Debug
- Debug de bateria (`DBT`), sensores IR (`DIR`), sensores frontais (`DFS`)

---

## Protocolo BLE

Todos os comandos terminam com `\r`. Exemplos:

| Comando | Ação |
|---------|------|
| `CLF\r` | Modo Line Follower |
| `CVL\r` | Modo Virtual Line |
| `COK\r` | Confirmar configuração |
| `SST\r` | Iniciar corrida |
| `SSP\r` | Parar corrida |
| `GC\r` | Calibrar giroscópio |
| `KOK\r` | Calibrar sensores |
| `PP,1.500\r` | Setar Kp = 1.5 |
| `VL,0.120\r` | Setar look-ahead = 12cm |
| `VG,0.70\r` | Setar ganho PP = 0.7 |

---

## Stack

- **Flutter** 3.x
- **flutter_reactive_ble** — comunicação BLE
- **provider** — gerenciamento de estado
- **fl_chart** — gráficos de telemetria
- **google_fonts** — tipografia

---

## Como rodar

```bash
# Instalar dependências
flutter pub get

# Rodar no Android
flutter run

# Build APK
flutter build apk --release
```

> Requer Android 6.0+ com Bluetooth LE e permissões de localização habilitadas.

---

## Estrutura do projeto

```
lib/
├── core/
│   ├── ble/          # Protocolo e serviço BLE
│   └── theme/        # Cores e tema do app
├── models/           # Estruturas de dados
├── providers/        # Estado global (BLE, Robot, Telemetry, Terminal)
├── screens/
│   ├── connection/   # Tela de conexão BLE
│   ├── dashboard/    # Dashboard principal
│   ├── control/      # PID, Calibração, Configuração, Corrida
│   ├── virtual_line/ # Controle do Pure Pursuit
│   ├── telemetry/    # Gráficos em tempo real
│   ├── terminal/     # Terminal BLE raw
│   ├── debug/        # Debug de sensores
│   └── demo/         # Modo demonstração
└── widgets/          # Componentes reutilizáveis
```

---

## Equipe

**Phoenix Unicamp** — Equipe de robótica seguidor de linha

> Firmware do robô: [phoenix-unicamp/seguidor-linha-code-2026](https://github.com/phoenix-unicamp/seguidor-linha-code-2026)
