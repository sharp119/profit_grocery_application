import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/constants/app_theme.dart';
import '../../../services/product/product_dynamic_data_provider.dart';
import '../../../services/product/product_service.dart';
import '../../../services/logging_service.dart';
import '../../../tools/rtdb_tester.dart';
import '../../../tools/rtdb_sample_data.dart';

/// Debug page for testing RTDB connections and diagnosing issues
class RTDBDebugPage extends StatefulWidget {
  const RTDBDebugPage({Key? key}) : super(key: key);

  @override
  State<RTDBDebugPage> createState() => _RTDBDebugPageState();
}

class _RTDBDebugPageState extends State<RTDBDebugPage> {
  final _productIdController = TextEditingController();
  final _categoryGroupController = TextEditingController();
  final _categoryItemController = TextEditingController();
  final _pathController = TextEditingController();
  final _valueController = TextEditingController();
  final _newPriceController = TextEditingController();
  
  final _rtdbTester = RTDBTester();
  final _sampleDataGenerator = RTDBSampleDataGenerator();
  final _dynamicDataProvider = GetIt.instance<ProductDynamicDataProvider>();
  final _productService = GetIt.instance<ProductService>();
  
  String _testResults = 'No tests run yet';
  Map<String, dynamic> _productData = {};
  bool _isLoading = false;
  String _monitoringPath = '';
  
  @override
  void initState() {
    super.initState();
    
    // Default values for testing
    _categoryGroupController.text = 'fruits_vegetables';
    _categoryItemController.text = 'fresh_fruits';
    _pathController.text = 'test_connection';
    _newPriceController.text = '199.9';
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _categoryGroupController.dispose();
    _categoryItemController.dispose();
    _pathController.dispose();
    _valueController.dispose();
    _newPriceController.dispose();
    _rtdbTester.stopAll();
    super.dispose();
  }
  
  Future<void> _runConnectionTest() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing connection...';
    });
    
    final success = await _rtdbTester.testConnection();
    
    setState(() {
      _isLoading = false;
      _testResults = success 
          ? 'Connection successful! Test data written to test_connection node.' 
          : 'Connection failed. Check logs for details.';
    });
  }
  
  Future<void> _fetchProduct() async {
    if (_productIdController.text.isEmpty) {
      setState(() {
        _testResults = 'Please enter a product ID';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _testResults = 'Fetching product data...';
      _productData = {};
    });
    
    try {
      // First try to get static data from Firestore
      final product = await _productService.getProductById(_productIdController.text);
      
      if (product != null) {
        setState(() {
          _productData = {
            'id': product.id,
            'name': product.name,
            'price': product.price,
            'inStock': product.inStock,
            'categoryId': product.categoryId,
            'categoryGroup': product.categoryGroup,
          };
          
          // Auto-fill category fields if available
          if (product.categoryGroup != null && product.categoryGroup!.isNotEmpty) {
            _categoryGroupController.text = product.categoryGroup!;
          }
          if (product.categoryId.isNotEmpty) {
            _categoryItemController.text = product.categoryId;
          }
          
          _testResults = 'Static product data loaded from Firestore';
        });
      } else {
        setState(() {
          _testResults = 'Product not found in Firestore';
        });
      }
      
      // Then try to get dynamic data from RTDB
      final categoryGroup = _categoryGroupController.text;
      final categoryItem = _categoryItemController.text;
      
      if (categoryGroup.isNotEmpty && categoryItem.isNotEmpty) {
        final path = 'products/$categoryGroup/items/$categoryItem/products/${_productIdController.text}';
        
        // Monitor this path
        _monitorPath(path);
      }
      
    } catch (e) {
      setState(() {
        _testResults = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _monitorPath(String path) {
    // Stop monitoring previous path
    if (_monitoringPath.isNotEmpty) {
      _rtdbTester.stopMonitoring(_monitoringPath);
    }
    
    // Start monitoring new path
    _rtdbTester.monitorPath(path);
    
    setState(() {
      _monitoringPath = path;
      _testResults = 'Monitoring path: $path';
    });
  }
  
  Future<void> _updateTestValue() async {
    if (_pathController.text.isEmpty) {
      setState(() {
        _testResults = 'Please enter a path';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _testResults = 'Updating value...';
    });
    
    try {
      final path = _pathController.text;
      final value = _valueController.text.isEmpty 
          ? {'testValue': 'Updated at ${DateTime.now()}', 'timestamp': DateTime.now().millisecondsSinceEpoch}
          : _valueController.text;
      
      final success = await _rtdbTester.updateValue(path, value);
      
      setState(() {
        _isLoading = false;
        _testResults = success 
            ? 'Value updated successfully' 
            : 'Update failed. Check logs for details.';
      });
      
      // Monitor this path
      _monitorPath(path);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResults = 'Error: $e';
      });
    }
  }
  
  Future<void> _updatePrice() async {
    if (_productIdController.text.isEmpty) {
      setState(() {
        _testResults = 'Please enter a product ID';
      });
      return;
    }
    
    if (_newPriceController.text.isEmpty) {
      setState(() {
        _testResults = 'Please enter a new price';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _testResults = 'Updating product price...';
    });
    
    try {
      final productId = _productIdController.text;
      final price = double.tryParse(_newPriceController.text) ?? 0.0;
      
      if (price <= 0) {
        setState(() {
          _isLoading = false;
          _testResults = 'Invalid price. Please enter a positive number.';
        });
        return;
      }
      
      final categoryGroup = _categoryGroupController.text;
      final categoryItem = _categoryItemController.text;
      
      final success = await _sampleDataGenerator.updateProductPriceById(productId, price);
      
      setState(() {
        _isLoading = false;
        _testResults = success 
            ? 'Price updated successfully to \$${price.toStringAsFixed(2)}' 
            : 'Price update failed. Check logs for details.';
      });
      
      // Monitor this product path
      if (categoryGroup.isNotEmpty && categoryItem.isNotEmpty) {
        _monitorPath('products/$categoryGroup/items/$categoryItem/products/$productId');
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResults = 'Error updating price: $e';
      });
    }
  }
  
  Future<void> _randomizePrices() async {
    if (_categoryGroupController.text.isEmpty || _categoryItemController.text.isEmpty) {
      setState(() {
        _testResults = 'Please enter a category group and item';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _testResults = 'Randomizing prices in category...';
    });
    
    try {
      final categoryGroup = _categoryGroupController.text;
      final categoryItem = _categoryItemController.text;
      
      final updatedCount = await _sampleDataGenerator.randomizeCategoryPrices(
        categoryGroup, 
        categoryItem
      );
      
      setState(() {
        _isLoading = false;
        _testResults = 'Updated $updatedCount product prices in $categoryGroup/$categoryItem';
      });
      
      // Monitor this category path
      _monitorPath('products/$categoryGroup/items/$categoryItem');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResults = 'Error randomizing prices: $e';
      });
    }
  }
  
  void _resetCache() {
    _dynamicDataProvider.clearCache();
    setState(() {
      _testResults = 'ProductDynamicDataProvider cache cleared';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RTDB Debug'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection test section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Test', 
                      style: TextStyle(
                        fontSize: 18.sp, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _runConnectionTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                      ),
                      child: Text(_isLoading ? 'Testing...' : 'Test Connection'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Product lookup section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Lookup', 
                      style: TextStyle(
                        fontSize: 18.sp, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _productIdController,
                      decoration: InputDecoration(
                        labelText: 'Product ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _categoryGroupController,
                      decoration: InputDecoration(
                        labelText: 'Category Group',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _categoryItemController,
                      decoration: InputDecoration(
                        labelText: 'Category Item',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _fetchProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                            ),
                            child: Text(_isLoading ? 'Fetching...' : 'Fetch Product'),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_productData.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'Product Data:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(_productData.toString()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Price update section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Update', 
                      style: TextStyle(
                        fontSize: 18.sp, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _newPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'New Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updatePrice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text(_isLoading ? 'Updating...' : 'Update Price'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _randomizePrices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: Text('Randomize'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Path value update section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Test Value', 
                      style: TextStyle(
                        fontSize: 18.sp, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _pathController,
                      decoration: InputDecoration(
                        labelText: 'Path',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _valueController,
                      decoration: InputDecoration(
                        labelText: 'Value (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Leave empty for timestamp',
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateTestValue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                            ),
                            child: Text(_isLoading ? 'Updating...' : 'Update Value'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: () => _monitorPath(_pathController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Monitor'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Cache controls section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Controls', 
                      style: TextStyle(
                        fontSize: 18.sp, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _resetCache,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Clear Product Dynamic Data Cache'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Results section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Results', 
                      style: TextStyle(
                        fontSize: 18.sp, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(_testResults),
                    ),
                    
                    if (_monitoringPath.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Monitoring: $_monitoringPath',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _rtdbTester.stopMonitoring(_monitoringPath);
                              setState(() {
                                _monitoringPath = '';
                                _testResults = 'Stopped monitoring';
                              });
                            },
                            child: const Text('Stop'),
                          ),
                        ],
                      ),
                    ],
                    
                    SizedBox(height: 8.h),
                    Text(
                      'Check logs for detailed RTDB events',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 