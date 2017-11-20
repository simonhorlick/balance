import 'package:balance/generated/rpc.pbgrpc.dart';
import 'package:flutter/material.dart';

class Transactions extends StatefulWidget {
  const Transactions(this.stub);

  final LightningClient stub;

  @override
  _TransactionsState createState() => new _TransactionsState();
}

class _TransactionsState extends State<Transactions> {

  List<Payment> payments;

  void initState() {
    super.initState();
    widget.stub.listPayments(ListPaymentsRequest.create()).then((response) {
      setState(() {
        payments = response.payments;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return payments == null ? new Container() : new TransactionsList(payments);
  }
}

class TransactionsList extends StatelessWidget {

  TransactionsList(this.payments);

  final List<Payment> payments;

  Widget buildListTile(BuildContext context, Payment payment) {
    return new MergeSemantics(
      child: new ListTile(
        isThreeLine: true,
        dense: false,
        leading: new ExcludeSemantics(
            child: new CircleAvatar(child: new Text(payment.paymentHash))),
        title: new Text(payment.paymentHash),
        subtitle: new Text('Sent ${payment.value} with fee ${payment.fee}'),
        trailing: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> listTiles =
      payments.map((payment) => buildListTile(context, payment));

    return new Scrollbar(
      child: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        children: listTiles.toList(),
      ),
    );
  }
}