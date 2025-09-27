import cv2
import mediapipe as mp
import numpy as np
import pickle
import os
from sklearn.metrics import accuracy_score, f1_score, precision_recall_fscore_support, hamming_loss, jaccard_score
import pandas as pd

class PosturePredictor:
    def __init__(self, model_path="model.pkl"):
        """Initialize predictor with trained model"""
        self.model_path = model_path
        self.load_model()
        
        # Initialize MediaPipe
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=True,
            model_complexity=2,
            enable_segmentation=False,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.5
        )
        
    def load_model(self):
        """Load trained model pipeline"""
        try:
            with open(self.model_path, 'rb') as f:
                model_data = pickle.load(f)
            
            self.model = model_data['best_model']
            self.model_name = model_data['best_model_name']
            self.scaler = model_data['scaler']
            self.selected_features = model_data.get('selected_features', None)
            self.labels = model_data['labels']
            
            print(f"✅ Model loaded successfully!")
            print(f"   Model: {self.model_name}")
            print(f"   Labels: {', '.join(self.labels)}")
            print(f"   Features: {len(self.selected_features) if self.selected_features is not None else 'All'}")
            
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            raise
    
    def extract_pose_landmarks(self, image_path):
        """Extract pose landmarks from image"""
        try:
            image = cv2.imread(image_path)
            if image is None:
                return None
                
            # Enhance image quality
            image = cv2.convertScaleAbs(image, alpha=1.2, beta=10)
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            results = self.pose.process(image_rgb)
            
            if results.pose_landmarks:
                landmarks = []
                for landmark in results.pose_landmarks.landmark:
                    landmarks.extend([landmark.x, landmark.y, landmark.z, landmark.visibility])
                return landmarks
            else:
                return None
        except Exception as e:
            print(f"Error processing {image_path}: {e}")
            return None
    
    def angle_between_vectors(self, v1, v2):
        """Calculate angle between two vectors"""
        try:
            v1_norm = v1 / np.linalg.norm(v1)
            v2_norm = v2 / np.linalg.norm(v2)
            cos_angle = np.clip(np.dot(v1_norm, v2_norm), -1.0, 1.0)
            angle = np.degrees(np.arccos(cos_angle))
            return angle
        except:
            return 0.0
    
    def calculate_enhanced_features(self, landmarks):
        """Calculate enhanced features (same as training)"""
        if len(landmarks) != 132:
            return []
            
        points = np.array(landmarks).reshape(-1, 4)
        features = []
        
        try:
            # Define key anatomical landmarks
            nose = points[0][:3]
            left_eye = points[1][:3]
            right_eye = points[2][:3]
            left_ear = points[7][:3]
            right_ear = points[8][:3]
            left_shoulder = points[11][:3]
            right_shoulder = points[12][:3]
            left_elbow = points[13][:3]
            right_elbow = points[14][:3]
            left_wrist = points[15][:3]
            right_wrist = points[16][:3]
            left_hip = points[23][:3]
            right_hip = points[24][:3]
            left_knee = points[25][:3]
            right_knee = points[26][:3]
            
            # Calculate centers
            eye_center = (left_eye + right_eye) / 2
            ear_center = (left_ear + right_ear) / 2
            shoulder_center = (left_shoulder + right_shoulder) / 2
            elbow_center = (left_elbow + right_elbow) / 2
            wrist_center = (left_wrist + right_wrist) / 2
            hip_center = (left_hip + right_hip) / 2
            knee_center = (left_knee + right_knee) / 2
            
            # Body dimensions for normalization
            shoulder_width = np.linalg.norm(left_shoulder - right_shoulder)
            torso_length = np.linalg.norm(shoulder_center - hip_center)
            
            # Forward head features (10)
            if torso_length > 0:
                ear_shoulder_offset = np.linalg.norm(ear_center[:2] - shoulder_center[:2]) / torso_length
                features.append(ear_shoulder_offset)
                eye_shoulder_offset = np.linalg.norm(eye_center[:2] - shoulder_center[:2]) / torso_length
                features.append(eye_shoulder_offset)
                nose_shoulder_offset = np.linalg.norm(nose[:2] - shoulder_center[:2]) / torso_length
                features.append(nose_shoulder_offset)
            else:
                features.extend([0, 0, 0])
            
            vertical = np.array([0, 1])
            head_vector = ear_center[:2] - shoulder_center[:2]
            if np.linalg.norm(head_vector) > 0:
                head_angle = self.angle_between_vectors(head_vector, vertical)
                features.append(head_angle)
            else:
                features.append(0)
            
            ear_eye_vector = ear_center[:2] - eye_center[:2]
            if np.linalg.norm(ear_eye_vector) > 0 and np.linalg.norm(head_vector) > 0:
                cranio_angle = self.angle_between_vectors(ear_eye_vector, head_vector)
                features.append(cranio_angle)
            else:
                features.append(0)
            
            features.extend([
                abs(ear_center[0] - shoulder_center[0]),
                abs(nose[0] - shoulder_center[0]),
                ear_center[1] - shoulder_center[1],
                nose[1] - shoulder_center[1],
                abs(left_ear[1] - right_ear[1])
            ])
            
            # Kyphosis features (12)
            shoulder_hip_vector = shoulder_center[:2] - hip_center[:2]
            if np.linalg.norm(shoulder_hip_vector) > 0:
                shoulder_hip_angle = self.angle_between_vectors(shoulder_hip_vector, vertical)
                features.append(shoulder_hip_angle)
            else:
                features.append(0)
            
            head_shoulder_vector = ear_center[:2] - shoulder_center[:2]
            if (np.linalg.norm(head_shoulder_vector) > 0 and np.linalg.norm(shoulder_hip_vector) > 0):
                three_point_angle = self.angle_between_vectors(head_shoulder_vector, -shoulder_hip_vector)
                features.append(three_point_angle)
            else:
                features.append(0)
            
            if torso_length > 0:
                back_line = hip_center[:2] + vertical * torso_length
                shoulder_protraction = np.linalg.norm(shoulder_center[:2] - back_line) / torso_length
                features.append(shoulder_protraction)
            else:
                features.append(0)
            
            shoulder_height_diff = abs(left_shoulder[1] - right_shoulder[1])
            shoulder_depth_diff = abs(left_shoulder[2] - right_shoulder[2])
            features.extend([shoulder_height_diff, shoulder_depth_diff])
            
            if np.linalg.norm(elbow_center[:2] - shoulder_center[:2]) > 0:
                elbow_angle = self.angle_between_vectors(elbow_center[:2] - shoulder_center[:2], vertical)
                features.append(elbow_angle)
            else:
                features.append(0)
            
            if torso_length > 0:
                head_shoulder_distance = np.linalg.norm(ear_center - shoulder_center)
                compactness = head_shoulder_distance / torso_length
                features.append(compactness)
            else:
                features.append(0)
            
            # Additional kyphosis features
            if (np.linalg.norm(shoulder_center - elbow_center) > 0 and 
                np.linalg.norm(elbow_center - hip_center) > 0):
                shoulder_elbow_vector = elbow_center[:2] - shoulder_center[:2]
                elbow_hip_vector = hip_center[:2] - elbow_center[:2]
                thoracic_angle = self.angle_between_vectors(shoulder_elbow_vector, elbow_hip_vector)
                features.append(thoracic_angle)
                thoracic_depth = abs(elbow_center[2] - shoulder_center[2])
                features.append(thoracic_depth)
            else:
                features.extend([0, 0])
            
            neck_shoulder_angle_left = self.angle_between_vectors(left_ear[:2] - left_shoulder[:2], vertical)
            neck_shoulder_angle_right = self.angle_between_vectors(right_ear[:2] - right_shoulder[:2], vertical)
            features.extend([neck_shoulder_angle_left, neck_shoulder_angle_right])
            
            if shoulder_width > 0 and torso_length > 0:
                curvature_index = (shoulder_width / torso_length) * np.sin(np.radians(shoulder_hip_angle))
                features.append(curvature_index)
            else:
                features.append(0)
            
            # Pelvic tilt features (10)
            left_hip_knee_vector = left_knee[:2] - left_hip[:2]
            right_hip_knee_vector = right_knee[:2] - right_hip[:2]
            
            if np.linalg.norm(left_hip_knee_vector) > 0:
                left_pelvic_angle = self.angle_between_vectors(left_hip_knee_vector, vertical)
                features.append(left_pelvic_angle)
            else:
                features.append(0)
                
            if np.linalg.norm(right_hip_knee_vector) > 0:
                right_pelvic_angle = self.angle_between_vectors(right_hip_knee_vector, vertical)
                features.append(right_pelvic_angle)
            else:
                features.append(0)
            
            features.append((features[-2] + features[-1]) / 2)  # Average pelvic angle
            
            hip_height_diff = abs(left_hip[1] - right_hip[1])
            hip_depth_diff = abs(left_hip[2] - right_hip[2])
            features.extend([hip_height_diff, hip_depth_diff])
            
            if np.linalg.norm(shoulder_hip_vector) > 0:
                pelvic_compensation = self.angle_between_vectors(-shoulder_hip_vector, vertical)
                features.append(pelvic_compensation)
            else:
                features.append(0)
            
            if shoulder_width > 0:
                knee_forward = abs(knee_center[0] - hip_center[0]) / shoulder_width
                features.append(knee_forward)
            else:
                features.append(0)
            
            # Additional pelvic features
            if len(points) > 27:
                left_ankle = points[27][:3] if len(points) > 27 else left_knee
                right_ankle = points[28][:3] if len(points) > 28 else right_knee
                ankle_center = (left_ankle + right_ankle) / 2
                
                hip_ankle_vector = ankle_center[:2] - hip_center[:2]
                if np.linalg.norm(hip_ankle_vector) > 0:
                    lumbar_angle = self.angle_between_vectors(hip_ankle_vector, vertical)
                    features.append(lumbar_angle)
                else:
                    features.append(0)
            else:
                features.append(0)
            
            if torso_length > 0:
                pelvic_severity = (hip_height_diff + knee_forward * torso_length) / torso_length
                features.append(pelvic_severity)
            else:
                features.append(0)
            
            features.append(abs(hip_center[0] - shoulder_center[0]))  # Hip-shoulder alignment
            
            # Global alignment features (8)
            if torso_length > 0:
                head_hip_offset_x = abs(ear_center[0] - hip_center[0]) / torso_length
                head_hip_offset_y = abs(ear_center[1] - hip_center[1]) / torso_length
                features.extend([head_hip_offset_x, head_hip_offset_y])
            else:
                features.extend([0, 0])
            
            body_vector = hip_center[:2] - ear_center[:2]
            if np.linalg.norm(body_vector) > 0:
                body_lean = self.angle_between_vectors(body_vector, vertical)
                features.append(body_lean)
            else:
                features.append(0)
            
            if torso_length > 0:
                head_torso_ratio = np.linalg.norm(ear_center - shoulder_center) / torso_length
                features.append(head_torso_ratio)
            else:
                features.append(0)
            
            com_x = (ear_center[0] + shoulder_center[0] + hip_center[0]) / 3
            com_y = (ear_center[1] + shoulder_center[1] + hip_center[1]) / 3
            if torso_length > 0:
                com_deviation = np.sqrt((com_x - hip_center[0])**2 + (com_y - hip_center[1])**2) / torso_length
                features.append(com_deviation)
            else:
                features.append(0)
            
            base_of_support = shoulder_width
            if base_of_support > 0:
                lateral_stability = abs(com_x - hip_center[0]) / base_of_support
                features.append(lateral_stability)
            else:
                features.append(0)
            
            if torso_length > 0:
                anterior_stability = abs(com_y - hip_center[1]) / torso_length
                features.append(anterior_stability)
            else:
                features.append(0)
            
            total_deviation = np.sqrt(sum([f**2 for f in features[-10:]]))
            features.append(total_deviation)
            
            # Quality features (5)
            key_landmarks = [0, 7, 8, 11, 12, 23, 24]
            visibility_scores = [points[i][3] for i in key_landmarks]
            
            features.append(np.mean(visibility_scores))
            features.append(np.min(visibility_scores))
            features.append(np.std(visibility_scores))
            
            left_vis = np.mean([points[7][3], points[11][3], points[23][3]])
            right_vis = np.mean([points[8][3], points[12][3], points[24][3]])
            bilateral_confidence = 1.0 - abs(left_vis - right_vis)
            features.append(bilateral_confidence)
            
            pose_quality = np.mean(visibility_scores) * bilateral_confidence
            features.append(pose_quality)
            
        except Exception as e:
            print(f"Error calculating features: {e}")
            return []
            
        return features
    
    def predict_single_image(self, image_path):
        """Predict posture for a single image with normal priority rule"""
        # Extract features
        landmarks = self.extract_pose_landmarks(image_path)
        if not landmarks or len(landmarks) != 132:
            return {'error': 'Could not extract pose landmarks from image'}
            
        engineered_features = self.calculate_enhanced_features(landmarks)
        if not engineered_features or len(engineered_features) != 45:
            return {'error': 'Could not calculate enhanced features'}
            
        # Combine features
        features = landmarks + engineered_features
        features_scaled = self.scaler.transform([features])
        
        # Apply feature selection if available
        if self.selected_features is not None:
            features_final = features_scaled[:, self.selected_features]
        else:
            features_final = features_scaled
        
        # Get probabilities
        probabilities = self.model.predict_proba(features_final)
        
        # Extract probability for positive class (class 1) for each label
        prob_scores = []
        for i, label in enumerate(self.labels):
            if len(probabilities[i][0]) > 1:  # Binary classification
                prob_positive = probabilities[i][0][1]
            else:  # Single class case
                prob_positive = probabilities[i][0][0]
            prob_scores.append(prob_positive)
        
        # Apply normal priority rule
        normal_idx = self.labels.index('normal')
        normal_prob = prob_scores[normal_idx]
        
        predictions = [0] * len(self.labels)
        
        # If normal has highest probability, only normal is predicted
        if normal_prob == max(prob_scores) and normal_prob > 0.5:
            predictions[normal_idx] = 1
        else:
            # Standard multilabel prediction for non-normal cases
            for i, prob in enumerate(prob_scores):
                if i != normal_idx and prob > 0.5:  # Don't predict normal if other conditions exist
                    predictions[i] = 1
        
        # Format results
        results = {
            'image_path': image_path,
            'model_used': self.model_name,
            'predictions': {},
            'probabilities': {},
            'detected_conditions': [],
            'summary': {}
        }
        
        for i, label in enumerate(self.labels):
            results['predictions'][label] = bool(predictions[i])
            results['probabilities'][label] = float(prob_scores[i])
            
            if predictions[i]:
                results['detected_conditions'].append(label.replace('_', ' ').title())
        
        # Summary
        if not results['detected_conditions']:
            results['detected_conditions'] = ['No issues detected']
        
        results['summary'] = {
            'status': 'Normal' if predictions[normal_idx] else 'Issues Detected',
            'confidence': f"{max(prob_scores):.3f}",
            'total_conditions': sum(predictions)
        }
        
        return results
    
    def predict_batch_images(self, image_folder):
        """Predict posture for all images in a folder"""
        if not os.path.exists(image_folder):
            print(f"❌ Folder not found: {image_folder}")
            return
        
        supported_formats = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp', '.jfif'}
        image_files = []
        
        for file in os.listdir(image_folder):
            if os.path.splitext(file.lower())[1] in supported_formats:
                image_files.append(os.path.join(image_folder, file))
        
        if not image_files:
            print(f"❌ No supported images found in {image_folder}")
            return
        
        print(f"📁 Processing {len(image_files)} images from {image_folder}")
        print("="*80)
        
        results = []
        successful_predictions = 0
        
        for i, image_path in enumerate(image_files):
            print(f"\n[{i+1}/{len(image_files)}] Processing: {os.path.basename(image_path)}")
            
            result = self.predict_single_image(image_path)
            
            if 'error' in result:
                print(f"❌ {result['error']}")
                continue
            
            successful_predictions += 1
            results.append(result)
            
            # Display results
            print(f"📊 Status: {result['summary']['status']}")
            print(f"🎯 Confidence: {result['summary']['confidence']}")
            print(f"🔍 Detected: {', '.join(result['detected_conditions'])}")
            
            print("   Detailed probabilities:")
            for label, prob in result['probabilities'].items():
                status = "✅" if result['predictions'][label] else "❌"
                print(f"     {status} {label.replace('_', ' ').title():<25}: {prob:.3f}")
        
        # Summary statistics
        print(f"\n{'='*80}")
        print(f"BATCH PREDICTION SUMMARY")
        print(f"{'='*80}")
        print(f"Total images processed: {len(image_files)}")
        print(f"Successful predictions: {successful_predictions}")
        print(f"Failed predictions: {len(image_files) - successful_predictions}")
        
        if results:
            # Count detections
            label_counts = {label: 0 for label in self.labels}
            for result in results:
                for label, detected in result['predictions'].items():
                    if detected:
                        label_counts[label] += 1
            
            print(f"\nDetection counts:")
            for label, count in label_counts.items():
                percentage = (count / len(results)) * 100
                print(f"  {label.replace('_', ' ').title():<25}: {count:3d} ({percentage:5.1f}%)")
        
        return results
    
    def evaluate_on_test_data(self, csv_file):
        """Evaluate model on test dataset and show metrics"""
        print(f"📊 Evaluating model on test dataset: {csv_file}")
        
        if not os.path.exists(csv_file):
            print(f"❌ CSV file not found: {csv_file}")
            return
        
        df = pd.read_csv(csv_file)
        
        y_true = []
        y_pred = []
        y_prob = []
        successful_predictions = 0
        
        for idx, row in df.iterrows():
            print(f"Evaluating {idx+1}/{len(df)}: {os.path.basename(row['filepath'])}", end='\r')
            
            result = self.predict_single_image(row['filepath'])
            
            if 'error' in result:
                continue
            
            # Ground truth
            true_labels = [int(row[label]) for label in self.labels]
            y_true.append(true_labels)
            
            # Predictions
            pred_labels = [int(result['predictions'][label]) for label in self.labels]
            y_pred.append(pred_labels)
            
            # Probabilities
            prob_labels = [result['probabilities'][label] for label in self.labels]
            y_prob.append(prob_labels)
            
            successful_predictions += 1
        
        if not y_true:
            print("❌ No successful predictions for evaluation")
            return
        
        y_true = np.array(y_true)
        y_pred = np.array(y_pred)
        y_prob = np.array(y_prob)
        
        print(f"\n{'='*80}")
        print(f"MODEL EVALUATION RESULTS")
        print(f"{'='*80}")
        print(f"Test samples: {len(y_true)}")
        print(f"Model: {self.model_name}")
        
        # Multilabel metrics
        hamming = hamming_loss(y_true, y_pred)
        jaccard_samples = jaccard_score(y_true, y_pred, average='samples')
        jaccard_macro = jaccard_score(y_true, y_pred, average='macro')
        f1_macro = f1_score(y_true, y_pred, average='macro')
        f1_micro = f1_score(y_true, y_pred, average='micro')
        
        print(f"\n📈 Overall Metrics:")
        print(f"  Hamming Loss (lower=better): {hamming:.4f}")
        print(f"  Jaccard Score (samples):     {jaccard_samples:.4f}")
        print(f"  Jaccard Score (macro):       {jaccard_macro:.4f}")
        print(f"  F1-Score (macro):           {f1_macro:.4f}")
        print(f"  F1-Score (micro):           {f1_micro:.4f}")
        
        # Per-label metrics
        precision, recall, f1, support = precision_recall_fscore_support(
            y_true, y_pred, average=None, zero_division=0
        )
        
        print(f"\n📊 Per-Label Performance:")
        print(f"  {'Label':<25} {'Precision':<10} {'Recall':<10} {'F1-Score':<10} {'Support':<10}")
        print(f"  {'-'*75}")
        
        for i, label in enumerate(self.labels):
            print(f"  {label.replace('_', ' ').title():<25} {precision[i]:<10.3f} {recall[i]:<10.3f} {f1[i]:<10.3f} {support[i]:<10.0f}")
        
        # Confusion matrices per label
        print(f"\n🔍 Detailed Analysis:")
        for i, label in enumerate(self.labels):
            tp = np.sum((y_true[:, i] == 1) & (y_pred[:, i] == 1))
            tn = np.sum((y_true[:, i] == 0) & (y_pred[:, i] == 0))
            fp = np.sum((y_true[:, i] == 0) & (y_pred[:, i] == 1))
            fn = np.sum((y_true[:, i] == 1) & (y_pred[:, i] == 0))
            
            accuracy = (tp + tn) / (tp + tn + fp + fn) if (tp + tn + fp + fn) > 0 else 0
            
            print(f"  {label.replace('_', ' ').title():<25}: Accuracy={accuracy:.3f} | TP={tp:2d} TN={tn:2d} FP={fp:2d} FN={fn:2d}")
        
        return {
            'hamming_loss': hamming,
            'jaccard_samples': jaccard_samples,
            'jaccard_macro': jaccard_macro,
            'f1_macro': f1_macro,
            'f1_micro': f1_micro,
            'per_label_metrics': {
                'precision': precision.tolist(),
                'recall': recall.tolist(),
                'f1': f1.tolist(),
                'support': support.tolist()
            }
        }