import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swift_order/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:swift_order/service/refund_service.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final RefundService _refundService = RefundService();
  late Future<OrderModel?> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrder();
  }

  Future<OrderModel?> _fetchOrder() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .get();

      if (!doc.exists) return null;
      return OrderModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error fetching order: $e');
      return null;
    }
  }

  void _showRefundDialog(OrderModel order) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Request Refund'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please provide a reason for your refund request:',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Reason',
                      hintText: 'Enter your reason for refund',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a reason';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await _refundService.requestRefund(
                        orderId: order.orderId,
                        buyerId: order.buyerId,
                        reason: reasonController.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Refund request submitted successfully',
                            ),
                          ),
                        );
                        setState(() {
                          _orderFuture = _fetchOrder();
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to request refund: ${e.toString()}',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Submit Request'),
              ),
            ],
          ),
    );
  }

  Future<bool> _checkRefundEligibility(String orderId) async {
    try {
      return await _refundService.canRequestRefund(orderId);
    } catch (e) {
      debugPrint('Error checking refund eligibility: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        elevation: 0,
        centerTitle: true,
        actions: [
          FutureBuilder<OrderModel?>(
            future: _orderFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return FutureBuilder<bool>(
                  future: _checkRefundEligibility(snapshot.data!.orderId),
                  builder: (context, eligibilitySnapshot) {
                    if (eligibilitySnapshot.data == true) {
                      return IconButton(
                        icon: const Icon(Icons.replay),
                        tooltip: 'Request Refund',
                        onPressed: () => _showRefundDialog(snapshot.data!),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<OrderModel?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Order not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data!;
          final formattedDate = DateFormat(
            'MMM dd, yyyy',
          ).format(order.timestamp.toLocal());
          final formattedRefundDate =
              order.refundProcessedAt != null
                  ? DateFormat(
                    'MMM dd, yyyy',
                  ).format(order.refundProcessedAt!.toLocal())
                  : null;

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderStatusCard(order, formattedRefundDate),
                  const SizedBox(height: 16),
                  _buildOrderInfoCard(order, formattedDate),
                  const SizedBox(height: 16),
                  _buildItemsCard(order),
                  const SizedBox(height: 16),
                  _buildTotalCard(order),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderStatusCard(OrderModel order, String? refundDate) {
    Color statusColor;
    IconData statusIcon;
    String statusText = order.status;

    switch (order.status) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Processed':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'Refunded':
        statusColor = Colors.blue;
        statusIcon = Icons.attach_money;
        statusText = 'Refund Completed';
        break;
      case 'Refund Requested':
        statusColor = Colors.purple;
        statusIcon = Icons.pending_actions;
        statusText = 'Refund Pending Approval';
        break;
      default: // 'Pending'
        statusColor = Colors.red;
        statusIcon = Icons.pending;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: statusColor.withOpacity(0.1),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.orderId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (order.refundRequested && order.status != 'Refunded')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Refund Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      order.refundReason ?? 'No reason provided',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            if (order.status == 'Refunded' && refundDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Refund processed on $refundDate',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            if (order.status == 'Pending' || order.status == 'Processed')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FutureBuilder<bool>(
                  future: _checkRefundEligibility(order.orderId),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _showRefundDialog(order),
                          child: const Text('Request Refund'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order, String formattedDate) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow('Vendor', order.vendorName),
            const SizedBox(height: 8),
            _buildInfoRow('Order Date', formattedDate),
            const SizedBox(height: 8),
            _buildInfoRow('Order ID', order.orderId),
            if (order.refundRequested) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Refund Status',
                order.status == 'Refunded' ? 'Refunded' : 'Requested',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: order.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unit price: RM ${item.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'RM ${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(OrderModel order) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 14)),
                Text(
                  'RM ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'RM ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (order.status == 'Refunded') ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Refund Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    'RM ${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
