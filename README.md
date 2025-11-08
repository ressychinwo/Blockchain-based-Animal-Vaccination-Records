# 🐾 Blockchain-based Animal Vaccination Records

A secure and transparent smart contract system for managing animal vaccination records on the Stacks blockchain. This contract enables veterinarians, pet owners, and animal registries to maintain comprehensive vaccination histories in a decentralized manner.

## 🌟 Features

- **🏥 Veterinarian Registration**: Licensed veterinarians can register and manage their credentials
- **🐕 Animal Registration**: Pet owners can register their animals with detailed information
- **💉 Vaccination Tracking**: Complete vaccination records with expiration dates and batch numbers
- **🔐 Access Control**: Role-based permissions ensuring only authorized users can modify records
- **🔄 Ownership Transfer**: Secure transfer of animal ownership between parties
- **📊 Vaccination Status**: Easy checking of vaccination expiration and due dates

## 🏗 Architecture

### Data Maps

1. **Animals Map**: Stores animal information including owner, species, breed, and microchip ID
2. **Veterinarians Map**: Manages licensed veterinarian credentials and clinic information
3. **Vaccinations Map**: Records all vaccination details with batch numbers and dates
4. **Animal-Vaccinations Map**: Links animals to their vaccination records

### Key Functions

#### 👨‍⚕️ Veterinarian Functions
- `register-veterinarian`: Register as a licensed veterinarian
- `deactivate-veterinarian`: Deactivate veterinarian account
- `add-vaccination`: Add vaccination record for an animal
- `update-vaccination-notes`: Update vaccination notes

#### 🐾 Animal Owner Functions
- `register-animal`: Register a new animal
- `update-animal`: Update animal information
- `transfer-animal-ownership`: Transfer ownership to another user
- `deactivate-animal`: Deactivate animal record

#### 📖 Read-Only Functions
- `get-animal`: Retrieve animal information
- `get-veterinarian`: Get veterinarian details
- `get-vaccination`: Get vaccination record
- `is-vaccination-expired`: Check if vaccination is expired
- `get-animal-owner`: Get current animal owner

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- [Node.js](https://nodejs.org/) for running tests

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Blockchain-based-Animal-Vaccination-Records.git
cd Blockchain-based-Animal-Vaccination-Records
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## 📝 Usage Examples

### Registering as a Veterinarian

```clarity
(contract-call? .blockchain-based-animal-vaccination-recor register-veterinarian 
    "Dr. Sarah Johnson" 
    "VET123456" 
    "Happy Paws Veterinary Clinic")
```

### Registering an Animal

```clarity
(contract-call? .blockchain-based-animal-vaccination-recor register-animal 
    "Buddy" 
    "Dog" 
    "Golden Retriever" 
    u1000 
    "CHIP123456789")
```

### Adding a Vaccination Record

```clarity
(contract-call? .blockchain-based-animal-vaccination-recor add-vaccination 
    u1 
    "Rabies Vaccine" 
    "VetMed Corp" 
    "BATCH789" 
    u2000 
    u3000 
    (some u2500) 
    "Annual rabies vaccination completed")
```

### Checking Vaccination Status

```clarity
(contract-call? .blockchain-based-animal-vaccination-recor is-vaccination-expired u1)
```

## 🔒 Security Features

- **Role-based Access Control**: Only registered veterinarians can add vaccination records
- **Ownership Verification**: Animal owners can only modify their own animals
- **Data Integrity**: Immutable vaccination records ensure historical accuracy
- **Input Validation**: Comprehensive parameter validation prevents invalid data entry

## ⚡ Error Codes

- `u400` - Invalid parameters provided
- `u401` - Unauthorized access attempt
- `u404` - Record not found
- `u409` - Record already exists
- `u410` - Vaccination expired

## 🧪 Testing

The contract includes comprehensive test coverage:

```bash
npm test
```

Tests cover:
- Veterinarian registration and management
- Animal registration and updates
- Vaccination record creation and validation
- Access control and permissions
- Edge cases and error handling



## 📄 License

This project is licensed under the MIT License 


*Made with ❤️ for the animal welfare community*



