# 📱 TurnoApp – Sistema de Reservas para Barberos y Salones

**Versión:** 1.0  
**Fecha:** Noviembre 2025  
**Desarrollador Principal:** **Berlyng M. Yena G.**

---

## 🧾 Resumen Ejecutivo

**TurnoApp** es una aplicación móvil de gestión de citas en tiempo real que conecta CLIENTES con BARBEROS sin necesidad de llamadas telefónicas ni manejo manual de calendarios.

✔ Arquitectura **Serverless**  
✔ Comunicación **bidireccional Cliente ↔ Barbero**  
✔ Actualización **en tiempo real con Firebase**  
✔ Escalable, segura y multiplataforma (**Flutter**)  

---

## 🏗️ Arquitectura del Sistema

TurnoApp utiliza un modelo **Backend-as-a-Service (BaaS)** desacoplado, basado en Firebase + Flutter.

### 📌 Componentes Principales

| Componente | Tecnología | Propósito |
|-----------|------------|-----------|
| Frontend | Flutter (Dart) | Interfaz multiplataforma (iOS / Android) |
| Base de Datos | Firebase Firestore | Datos en tiempo real |
| Autenticación | Firebase Authentication | Login + roles (cliente/barbero) |
| Gestión de archivos | Firebase Storage | Fotos de perfil *(pendiente)* |
| Backend serverless | Firebase Cloud Functions | Notificaciones + lógica de negocio |

---

## 🔄 Flujo de Datos – Reserva de Cita

```mermaid
sequenceDiagram
    participant Cliente
    participant Flutter
    participant Firestore
    participant CloudFunctions
    participant Barbero

    Cliente->>Flutter: Solicita cita (serviceId, barberId, dateTime)
    Flutter->>Firestore: addDoc() en appointments (status: pending)
    Firestore-->>CloudFunctions: Trigger onCreate/onWrite
    CloudFunctions->>Barbero: Notificación Push (FCM)
    Barbero->>Firestore: Actualiza status (confirmed / rejected)
    Firestore-->>Cliente: UI actualizada automáticamente (StreamBuilder)


