// widgets/reviews_list.dart
import 'package:flutter/material.dart';
import 'package:swift_order/models/review_model.dart';
import 'package:swift_order/service/review_service.dart';
import 'package:provider/provider.dart';

class ReviewsList extends StatelessWidget {
  final String vendorId;

  const ReviewsList({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: Provider.of<ReviewService>(context).getVendorReviews(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No reviews yet'));
        }

        final reviews = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(child: Text(review.userName[0])),
                        const SizedBox(width: 8),
                        Text(
                          review.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        ...List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (review.comment.isNotEmpty) Text(review.comment),
                    const SizedBox(height: 8),
                    Text(
                      '${review.timestamp.day}/${review.timestamp.month}/${review.timestamp.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
