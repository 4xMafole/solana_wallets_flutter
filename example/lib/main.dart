import 'package:flutter/material.dart';
import 'package:solana_wallets_flutter/solana_wallets_flutter.dart';
import 'package:solana_wallets_flutter/solana_wallets_flutter_ui.dart';

void main() async {
  initSolanaWallets();
  runApp(const MyApp());
}

class AboutButton extends StatelessWidget {
  const AboutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => IconButton(
      onPressed: () {
        showAboutDialog(context: context);
      },
      tooltip: 'About',
      icon: const Icon(Icons.info));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: const [AboutButton()],
        ),
        body: const Center(child: SelectButton()),
      ),
    );
  }
}

class SelectButton extends StatefulWidget {
  const SelectButton({Key? key}) : super(key: key);

  @override
  _SelectButtonState createState() => _SelectButtonState();
}

class _SelectButtonState extends State<SelectButton> {
  BaseWalletAdapter? selected;
  List<BaseWalletAdapter>? adapters;
  @override
  void initState() {
    getWalletAdaptersWhenInitalized()
        .then((List<BaseWalletAdapter> value) => setState(() {
              adapters = value;
            }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (selected != null) {
      child = Column(
        children: [
          Text('Selected ${selected!.name}'),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  selected = null;
                });
              },
              child: const Text('Deselect')),
          ConnectionStateButton(adapter: selected!)
        ],
      );
    } else if (adapters != null) {
      child = MaterialButton(
          onPressed: () {
            showWalletSelectDialog(context: context, adapters: adapters!)
                .then((BaseWalletAdapter? value) {
              setState(() {
                selected = value;
              });
            });
          },
          child: const Text('Select Wallet'));
    } else {
      child = const CircularProgressIndicator();
    }
    return child;
  }
}

class ConnectionStateButton extends StatefulWidget {
  final BaseWalletAdapter adapter;
  const ConnectionStateButton({Key? key, required this.adapter})
      : super(key: key);

  @override
  _ConnectionStateButtonState createState() => _ConnectionStateButtonState();
}

class _ConnectionStateButtonState extends State<ConnectionStateButton> {
  @override
  void initState() {
    super.initState();
    widget.adapter.addListener(_setState);
  }

  void _setState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.adapter.removeListener(_setState);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _button(context),
        Text('Current state: ${widget.adapter.walletState}'),
        Text('Current Pubkey: ${widget.adapter.publicKey}')
      ],
    );
  }

  Widget _button(BuildContext context) {
    switch (widget.adapter.walletState) {
      case WalletState.unsupported:
      case WalletState.notDetected:
        return const ElevatedButton(onPressed: null, child: Text('Connect'));
      case WalletState.loadable:
      case WalletState.installed:
        return ElevatedButton(
            onPressed: () {
              widget.adapter
                  .connect()
                  .catchError((Object error, StackTrace trace) {
                print('ERROR!');
                print(error);
                print(trace);
              });
            },
            child: const Text('Connect'));
      case WalletState.connecting:
        return const ElevatedButton(
            onPressed: null, child: Text('Connecting...'));
      case WalletState.connected:
        return ElevatedButton(
            onPressed: () {
              widget.adapter
                  .disconnect()
                  .catchError((Object error, StackTrace trace) {
                print('ERROR!');
                print(error);
                print(trace);
              });
            },
            child: const Text('Disconnect'));
      case WalletState.disconnecting:
        return const ElevatedButton(
            onPressed: null, child: Text('Disconnecting...'));
    }
  }
}