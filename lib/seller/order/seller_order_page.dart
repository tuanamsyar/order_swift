import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swift_order/models/order_model.dart';
import 'package:swift_order/service/seller_order_service.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  final SellerOrderService _orderService = SellerOrderService();
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderService.fetchSellerOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Orders")),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('Order ID: ${order.orderId}'),
                  subtitle: Text('Status: ${order.status}'),
                  children: [
                    ...order.items
                        .where(
                          (item) =>
                              item.sellerId ==
                              FirebaseAuth.instance.currentUser!.uid,
                        )
                        .map(
                          (item) => ListTile(
                            title: Text(item.name),
                            subtitle: Text('Qty: ${item.quantity}'),
                            trailing: Text(
                              'RM ${item.price.toStringAsFixed(2)}',
                            ),
                          ),
                        ),
                    ButtonBar(
                      alignment: MainAxisAlignment.end,
                      children: [
                        if (order.status == 'Pending')
                          ElevatedButton(
                            onPressed: () async {
                              await _orderService.updateOrderStatus(
                                order.orderId,
                                'Processed',
                              );
                              setState(() {
                                _ordersFuture =
                                    _orderService.fetchSellerOrders();
                              });
                            },
                            child: const Text('Mark as Processed'),
                          ),
                        if (order.status == 'Processed')
                          ElevatedButton(
                            onPressed: () async {
                              await _orderService.updateOrderStatus(
                                order.orderId,
                                'Completed',
                              );
                              setState(() {
                                _ordersFuture =
                                    _orderService.fetchSellerOrders();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Mark as Completed'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
