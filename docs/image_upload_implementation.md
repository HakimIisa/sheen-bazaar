# Image Upload Implementation

## Overview

This document describes the changes made to replace URL-based image input with real device image uploads across the vendor side of Sheen Bazaar. Vendors can now pick photos directly from their device gallery when creating a shop or adding/editing a product. Images are uploaded to Firebase Storage and the resulting download URL is saved to Firestore — the same `image`, `coverImage`, and `logo` fields that already existed.

---

## Firebase Setup (Manual Steps Completed)

### Storage Bucket
- Firebase Storage was enabled on the **Blaze (pay-as-you-go)** plan.
- Bucket: `gs://sheen-bazaar.firebaseapp.com`
- Region: `US-CENTRAL1` (no-cost location)

### Security Rules
The following rules were published under **Storage → Rules**:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

- **Read:** Public — anyone (including unauthenticated users browsing the app) can view images.
- **Write:** Restricted to authenticated users only — only logged-in vendors can upload.

---

## Packages Added

In `pubspec.yaml`:

```yaml
firebase_storage: ^13.0.6
image_picker: ^1.1.2
```

| Package | Purpose |
|---------|---------|
| `firebase_storage` | Uploads files to Firebase Storage and retrieves download URLs |
| `image_picker` | Opens the device gallery to let the user select a photo |

---

## Android Permissions

Added to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Gallery access: Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<!-- Gallery access: Android 12 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

Android 13 (API 33) introduced `READ_MEDIA_IMAGES` as a replacement for `READ_EXTERNAL_STORAGE`. Both are declared so the app works correctly across all Android versions. The `maxSdkVersion="32"` attribute ensures the old permission is only requested on devices that need it.

---

## Image Constraints

Enforced inside `ImageUploadService` before any upload is attempted:

| Constraint | Value | Reason |
|------------|-------|--------|
| Allowed formats | JPEG, PNG | Consistent rendering across Android versions; WebP excluded due to inconsistent older-device support |
| Maximum file size | 5 MB | Sufficient for high-quality product photos while keeping upload times reasonable on mobile data |
| Image quality (picker) | 85% | Slight compression applied at pick time to reduce file size without visible quality loss |

If either constraint is violated, an `Exception` is thrown with a user-readable message, which surfaces as a SnackBar error in the UI.

---

## Storage Path Structure

Images are stored using predictable, shop-scoped paths:

```
shops/
└── {shopId}/
    ├── cover.jpg          ← shop cover image
    ├── logo.jpg           ← shop logo
    └── products/
        └── {productId}.jpg  ← product image
```

**Why this structure:**
- All assets belonging to a shop are grouped under its ID — easy to inspect in the Firebase console and easy to clean up if a shop is deleted in the future.
- Using the Firestore document ID as the filename means each upload overwrites the previous image for that entity rather than accumulating orphaned files.

### Option B — Pre-generated Document IDs
For new documents (new shop, new product), the Firestore document reference is created with `.doc()` *before* saving — this gives us the ID upfront without writing anything to the database yet. The image is uploaded using that ID, then the document is saved with `.set()`. This keeps the Storage filename and the Firestore document ID in sync.

---

## New Files

### `lib/services/image_upload_service.dart`

A single-responsibility service with two static methods:

| Method | Description |
|--------|-------------|
| `pickFromGallery()` | Opens the device gallery via `image_picker`. Returns the chosen `XFile`, or `null` if the user cancels. |
| `upload({image, storagePath})` | Validates format and size, uploads the file to Firebase Storage, returns the download URL. |

### `lib/widgets/image_picker_field.dart`

A reusable stateless widget used in both `create_shop.dart` and `manage_products.dart`. It renders:

- A **placeholder** (upload icon + "Tap to upload" text) when no image exists.
- A **local file preview** (`Image.file`) immediately after the user picks a photo, before it is uploaded.
- A **network image preview** (`Image.network`) when editing an existing record that already has an image URL.
- A **camera icon overlay** in the bottom-right corner to indicate the field is tappable.

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `label` | `String` | Field label rendered above the picker |
| `pickedFile` | `XFile?` | Locally picked file (shown as preview before upload) |
| `existingUrl` | `String` | Existing Firebase Storage URL (used in edit mode) |
| `aspectRatio` | `double` | Controls the shape — `16/7` for cover image, `1.0` for logo and product |
| `onPick` | `void Function(XFile)` | Callback invoked with the chosen file |

---

## Modified Files

### `lib/screens/shop_owner/create_shop.dart`

**Before:** Two `TextEditingController` fields (`_coverImageCtrl`, `_logoCtrl`) where vendors pasted image URLs manually.

**After:**
- Controllers removed.
- Two `XFile?` state variables added: `_coverImageFile`, `_logoFile`.
- Two `ImagePickerField` widgets replace the text fields:
  - Cover image uses `aspectRatio: 16/7` (wide banner shape).
  - Logo uses `aspectRatio: 1.0` (square).
- `_save()` now pre-generates the Firestore doc reference, uploads any picked images, then calls `.set()` (new) or `.update()` (edit).
- In edit mode, if the vendor does not pick a new image, the existing URL is preserved.

### `lib/screens/shop_owner/manage_products.dart`

**Before:** One `TextEditingController` field (`_imageCtrl`) in `AddEditProduct` where vendors pasted a product image URL.

**After:**
- Controller removed.
- One `XFile?` state variable added: `_imageFile`.
- `ImagePickerField` widget replaces the text field with `aspectRatio: 1.0` (square product photo).
- `_save()` pre-generates the Firestore doc reference, uploads any picked image, then calls `.set()` (new) or `.update()` (edit).
- In edit mode, if the vendor does not pick a new image, the existing URL is preserved.

---

## Data Flow

```
Vendor taps image field
        ↓
ImagePickerField calls image_picker (gallery, 85% quality)
        ↓
XFile returned → stored in widget state → shown as local preview
        ↓
Vendor taps Save
        ↓
ImageUploadService.upload() called
  → validates format (JPEG/PNG) and size (≤ 5 MB)
  → uploads File to Firebase Storage path
  → returns download URL (https://firebasestorage.googleapis.com/...)
        ↓
URL saved to Firestore (image / coverImage / logo field)
        ↓
Existing Image.network() widgets display it unchanged
```

---

## What Did Not Change

- The `image`, `coverImage`, and `logo` fields in Firestore remain plain strings (URLs). No schema migration needed.
- All `Image.network()` calls throughout the customer-facing screens (`shop_detail.dart`, `product_detail.dart`, etc.) continue to work without modification — Firebase Storage download URLs are standard HTTPS URLs.
- Existing shops and products that were created with pasted URLs continue to display correctly.
