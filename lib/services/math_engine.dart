// math_engine.dart
// Validates and solves mathematical expressions with step-by-step solutions

import 'dart:developer' as developer;
import 'dart:math' as math;

/// Result of math validation
class MathValidationResult {
  final bool valid;
  final List<String> issues;
  final String? correctedSteps;
  final Map<String, dynamic>? calculatedValues;

  MathValidationResult({
    required this.valid,
    List<String>? issues,
    this.correctedSteps,
    this.calculatedValues,
  }) : issues = issues ?? [];

  bool get hasIssues => issues.isNotEmpty;
}

/// Step in a mathematical solution
class MathStep {
  final String description;
  final String expression;
  final dynamic result;
  final String explanation;

  MathStep({
    required this.description,
    required this.expression,
    required this.result,
    this.explanation = '',
  });

  @override
  String toString() {
    return '$description: $expression = $result${explanation.isNotEmpty ? " ($explanation)" : ""}';
  }
}

/// Mathematical expression validator and solver
class MathEngine {
  /// Validate and annotate mathematical content in text
  static Future<MathValidationResult> validateAndAnnotate(String text) async {
    try {
      final issues = <String>[];
      final calculations = <String, dynamic>{};
      
      // Extract mathematical expressions
      final expressions = _extractMathExpressions(text);
      
      if (expressions.isEmpty) {
        return MathValidationResult(valid: true);
      }

      developer.log('Found ${expressions.length} math expressions to validate',
          name: 'MathEngine');

      final buffer = StringBuffer();
      buffer.writeln('Mathematical Validation:');
      buffer.writeln();

      for (final expr in expressions) {
        try {
          final result = _evaluateExpression(expr);
          calculations[expr] = result;
          
          // Check if the answer in text matches calculated result
          final textAnswer = _findAnswerNear(text, expr);
          if (textAnswer != null) {
            final calculated = result.toString();
            if (!_answersMatch(textAnswer, calculated)) {
              issues.add(
                  'Expression "$expr": Text says "$textAnswer" but calculation gives "$calculated"');
              buffer.writeln('❌ $expr');
              buffer.writeln('   Text answer: $textAnswer');
              buffer.writeln('   Correct answer: $calculated');
              buffer.writeln();
            } else {
              buffer.writeln('✓ $expr = $calculated');
            }
          }
        } catch (e) {
          developer.log('Error evaluating expression "$expr": $e',
              name: 'MathEngine', error: e);
          // Don't fail validation for complex expressions we can't parse
        }
      }

      final correctedSteps = issues.isNotEmpty ? buffer.toString() : null;

      return MathValidationResult(
        valid: issues.isEmpty,
        issues: issues,
        correctedSteps: correctedSteps,
        calculatedValues: calculations,
      );
    } catch (e) {
      developer.log('Error in validateAndAnnotate: $e',
          name: 'MathEngine', error: e);
      return MathValidationResult(
        valid: true, // Don't block on validation errors
        issues: ['Validation error: $e'],
      );
    }
  }

  /// Solve equation and show step-by-step solution
  static Future<List<MathStep>> solveAndShowSteps(String equation) async {
    final steps = <MathStep>[];

    try {
      // Parse equation (format: "expression = value" or just "expression")
      final parts = equation.split('=').map((p) => p.trim()).toList();
      
      if (parts.length == 1) {
        // Just an expression to evaluate
        final result = _evaluateExpression(parts[0]);
        steps.add(MathStep(
          description: 'Evaluate expression',
          expression: parts[0],
          result: result,
          explanation: 'Direct calculation',
        ));
      } else if (parts.length == 2) {
        // Equation to solve
        final left = parts[0];
        final right = parts[1];
        
        steps.add(MathStep(
          description: 'Original equation',
          expression: '$left = $right',
          result: equation,
          explanation: 'Starting point',
        ));

        // Evaluate both sides
        try {
          final leftResult = _evaluateExpression(left);
          final rightResult = _evaluateExpression(right);
          
          steps.add(MathStep(
            description: 'Evaluate left side',
            expression: left,
            result: leftResult,
          ));

          steps.add(MathStep(
            description: 'Evaluate right side',
            expression: right,
            result: rightResult,
          ));

          if (leftResult == rightResult) {
            steps.add(MathStep(
              description: 'Verification',
              expression: '$leftResult = $rightResult',
              result: true,
              explanation: 'Both sides are equal ✓',
            ));
          } else {
            steps.add(MathStep(
              description: 'Verification',
              expression: '$leftResult ≠ $rightResult',
              result: false,
              explanation: 'Sides are not equal - equation may need solving for a variable',
            ));
          }
        } catch (e) {
          steps.add(MathStep(
            description: 'Analysis',
            expression: equation,
            result: 'Cannot evaluate',
            explanation: 'May contain variables that need algebraic solving',
          ));
        }
      }

      developer.log('Generated ${steps.length} solution steps',
          name: 'MathEngine');
      
    } catch (e) {
      developer.log('Error in solveAndShowSteps: $e',
          name: 'MathEngine', error: e);
      steps.add(MathStep(
        description: 'Error',
        expression: equation,
        result: 'Error',
        explanation: 'Could not solve: $e',
      ));
    }

    return steps;
  }

  /// Extract mathematical expressions from text
  static List<String> _extractMathExpressions(String text) {
    final expressions = <String>[];
    
    // Pattern for basic arithmetic expressions
    final patterns = [
      RegExp(r'\b(\d+\.?\d*)\s*([+\-*/^])\s*(\d+\.?\d*)\b'),
      RegExp(r'\(([^)]+)\)'), // Parenthesized expressions
      RegExp(r'(\d+\.?\d*)\s*\^\s*(\d+)'), // Exponents
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final expr = match.group(0);
        if (expr != null && expr.isNotEmpty) {
          expressions.add(expr);
        }
      }
    }

    return expressions.toSet().toList(); // Remove duplicates
  }

  /// Evaluate a mathematical expression
  static dynamic _evaluateExpression(String expr) {
    try {
      // Clean expression
      var cleaned = expr.trim()
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('^', '**'); // Power operator

      // Handle special math functions
      cleaned = _replaceMathFunctions(cleaned);

      // Simple expression evaluator (supports basic arithmetic)
      return _simpleEval(cleaned);
    } catch (e) {
      // Try manual parsing for simple cases
      if (expr.contains('+')) {
        final parts = expr.split('+');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0].trim());
          final b = double.tryParse(parts[1].trim());
          if (a != null && b != null) return a + b;
        }
      }
      rethrow;
    }
  }

  /// Simple expression evaluator for basic arithmetic
  static double _simpleEval(String expr) {
    // Remove whitespace
    expr = expr.replaceAll(RegExp(r'\s+'), '');
    
    // Handle parentheses recursively
    while (expr.contains('(')) {
      final openIdx = expr.lastIndexOf('(');
      final closeIdx = expr.indexOf(')', openIdx);
      if (closeIdx == -1) throw FormatException('Unmatched parentheses');
      
      final innerExpr = expr.substring(openIdx + 1, closeIdx);
      final result = _simpleEval(innerExpr);
      expr = expr.substring(0, openIdx) + result.toString() + expr.substring(closeIdx + 1);
    }
    
    // Handle power operations first
    expr = _handlePowerOperations(expr);
    
    // Handle multiplication and division
    expr = _handleMultDiv(expr);
    
    // Handle addition and subtraction
    expr = _handleAddSub(expr);
    
    return double.parse(expr);
  }

  /// Handle power operations
  static String _handlePowerOperations(String expr) {
    while (expr.contains('**')) {
      final match = RegExp(r'(-?\d+\.?\d*)\*\*(-?\d+\.?\d*)').firstMatch(expr);
      if (match == null) break;
      
      final base = double.parse(match.group(1)!);
      final exp = double.parse(match.group(2)!);
      final result = math.pow(base, exp);
      
      expr = expr.substring(0, match.start) + 
             result.toString() + 
             expr.substring(match.end);
    }
    return expr;
  }

  /// Handle multiplication and division
  static String _handleMultDiv(String expr) {
    while (expr.contains('*') || expr.contains('/')) {
      final match = RegExp(r'(-?\d+\.?\d*)([*/])(-?\d+\.?\d*)').firstMatch(expr);
      if (match == null) break;
      
      final a = double.parse(match.group(1)!);
      final op = match.group(2)!;
      final b = double.parse(match.group(3)!);
      
      final result = op == '*' ? a * b : a / b;
      
      expr = expr.substring(0, match.start) + 
             result.toString() + 
             expr.substring(match.end);
    }
    return expr;
  }

  /// Handle addition and subtraction
  static String _handleAddSub(String expr) {
    while (expr.contains('+') || RegExp(r'\d-').hasMatch(expr)) {
      final match = RegExp(r'(-?\d+\.?\d*)([+\-])(-?\d+\.?\d*)').firstMatch(expr);
      if (match == null) break;
      
      final a = double.parse(match.group(1)!);
      final op = match.group(2)!;
      final b = double.parse(match.group(3)!);
      
      final result = op == '+' ? a + b : a - b;
      
      expr = expr.substring(0, match.start) + 
             result.toString() + 
             expr.substring(match.end);
    }
    return expr;
  }

  /// Replace math function names with evaluable expressions
  static String _replaceMathFunctions(String expr) {
    var result = expr;
    
    // Square root
    result = result.replaceAllMapped(
        RegExp(r'sqrt\(([^)]+)\)'),
        (m) => 'pow(${m.group(1)}, 0.5)');
    
    // Power
    result = result.replaceAll('**', '^');
    
    return result;
  }

  /// Find answer near an expression in text
  static String? _findAnswerNear(String text, String expression) {
    final exprIndex = text.indexOf(expression);
    if (exprIndex == -1) return null;

    // Look for "= number" pattern after expression
    final afterExpr = text.substring(exprIndex + expression.length);
    final answerMatch = RegExp(r'=\s*(-?\d+\.?\d*)').firstMatch(afterExpr);
    
    return answerMatch?.group(1);
  }

  /// Check if two answers match (with tolerance for floating point)
  static bool _answersMatch(String answer1, String answer2) {
    final num1 = double.tryParse(answer1);
    final num2 = double.tryParse(answer2);
    
    if (num1 != null && num2 != null) {
      return (num1 - num2).abs() < 0.0001; // Tolerance for floating point
    }
    
    return answer1.trim() == answer2.trim();
  }

  /// Validate a specific calculation with expected result
  static bool validateCalculation(String expression, dynamic expectedResult) {
    try {
      final result = _evaluateExpression(expression);
      return _answersMatch(result.toString(), expectedResult.toString());
    } catch (e) {
      developer.log('Error validating calculation: $e',
          name: 'MathEngine', error: e);
      return false;
    }
  }

  /// Get common mathematical formulas for reference
  static Map<String, String> getCommonFormulas() {
    return {
      'quadratic': 'x = (-b ± √(b² - 4ac)) / 2a',
      'area_rectangle': 'A = length × width',
      'area_circle': 'A = πr²',
      'circumference': 'C = 2πr',
      'pythagorean': 'a² + b² = c²',
      'distance': 'd = √((x₂-x₁)² + (y₂-y₁)²)',
      'slope': 'm = (y₂-y₁)/(x₂-x₁)',
    };
  }
}
