import numpy as np
from tensorflow import keras

# Load model
model = keras.models.load_model('../govi_sahaya_backend/src/ml/models/onion_disease_model.h5')

# Check model output
print("Model output shape:", model.output_shape)
print("Number of classes:", model.output_shape[-1])

# Test with random input
test_input = np.random.rand(1, 224, 224, 3)
test_pred = model.predict(test_input, verbose=0)

print("\nTest predictions:")
print("Shape:", test_pred.shape)
print("Sum:", test_pred.sum())  # Should be close to 1.0 if using softmax
print("Max value:", test_pred.max())
print("Max class index:", test_pred.argmax())
print("\nFirst 5 predictions:", test_pred[0][:5])

# Check if model always predicts the same thing
predictions_list = []
for i in range(5):
    random_input = np.random.rand(1, 224, 224, 3)
    pred = model.predict(random_input, verbose=0)
    predictions_list.append(pred.argmax())
    
print("\nRandom predictions (should vary):", predictions_list)

# Exit Python
exit()
