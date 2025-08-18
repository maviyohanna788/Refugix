# 🏠 Refugix - Refugee ID Registry

> 🔐 Non-custodial, verified displacement records on the blockchain

Refugix is a decentralized smart contract system built on Stacks that provides secure, verifiable identity management for refugees and displaced persons. The system ensures data sovereignty while enabling trusted verification by authorized organizations.

## ✨ Features

- 📝 **Self-Registration**: Refugees can register their own identity and displacement information
- 🔍 **Verification System**: Authorized NGOs and authorities can verify refugee status
- 📄 **Document Management**: Secure document upload with IPFS integration
- 📍 **Location Tracking**: Update current location while preserving origin data
- 🚨 **Emergency Contacts**: Maintain up-to-date emergency contact information
- 🏛️ **Authority Management**: Contract owner can manage verifier permissions

## 🚀 Quick Start

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation
```bash
git clone https://github.com/maviyohanna788/Refugix
cd Refugix
clarinet check
```

## 📋 Usage

### For Refugees

#### Register as a Refugee
```clarity
(contract-call? .Refugix register-refugee
  "John Doe"              ;; full-name
  "1990-01-15"           ;; date-of-birth  
  "Syrian"               ;; nationality
  "Syria"                ;; origin-country
  "Aleppo"               ;; origin-city
  "Berlin, Germany"      ;; current-location
  "Jane Doe +49123456789" ;; emergency-contact
  "+49987654321"         ;; phone-number
  "War displacement"      ;; displacement-reason
)
```

#### Update Your Location
```clarity
(contract-call? .Refugix update-location "Paris, France")
```

#### Upload Documents
```clarity
(contract-call? .Refugix upload-document
  u1                                    ;; refugee-id
  "passport"                           ;; document-type
  "abc123..."                          ;; document-hash
  "QmX1Y2Z3..."                        ;; ipfs-hash
)
```

### For Verifiers/NGOs

#### Verify a Refugee
```clarity
(contract-call? .Refugix verify-refugee u1 true)  ;; approve
(contract-call? .Refugix verify-refugee u2 false) ;; reject
```

#### Verify Documents
```clarity
(contract-call? .Refugix verify-document u1)
```

### For Contract Administrators

#### Add Authorized Verifier
```clarity
(contract-call? .Refugix add-verifier
  'SP1234...                           ;; verifier principal
  "UNHCR Officer"                      ;; name
  "United Nations High Commissioner"   ;; organization
)
```

## 📊 Status Codes

| Status | Code | Description |
|--------|------|-------------|
| Pending | `0` | 🕐 Registration submitted, awaiting verification |
| Verified | `1` | ✅ Identity verified by authorized verifier |
| Rejected | `2` | ❌ Verification rejected |
| Inactive | `3` | 😴 Account temporarily inactive |

## 🔍 Read-Only Functions

### Get Refugee Information
```clarity
(contract-call? .Refugix get-refugee u1)
(contract-call? .Refugix get-refugee-by-principal 'SP1234...)
```

### Check Verification Status
```clarity
(contract-call? .Refugix is-refugee-verified u1)
(contract-call? .Refugix get-refugee-status u1)
```

### View Documents
```clarity
(contract-call? .Refugix get-refugee-documents u1)
(contract-call? .Refugix get-document u1)
```

## 🛡️ Security Features

- **Non-custodial**: Refugees maintain control of their data
- **Immutable Records**: Blockchain ensures data integrity
- **Access Control**: Only authorized verifiers can change status
- **Document Verification**: Hash-based document authenticity
- **Privacy Preserving**: Sensitive data can be stored off-chain via IPFS

## ⚠️ Error Codes

| Code | Description |
|------|-------------|
| `100` | Not authorized |
| `101` | Already registered |
| `102` | Not found |
| `103` | Invalid status |
| `104` | Invalid verifier |
| `105` | Already verified |
| `106` | Invalid document |

## 🧪 Testing

Run tests using Clarinet:
```bash
clarinet test
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- 📧 Create an issue on GitHub
- 💬 Join our community discussions
- 📖 Check the documentation

---

*Built with love for refugees worldwide* 🌍
