package com.messenger.app.repository;

import com.messenger.app.model.Participant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ParticipantRepository extends JpaRepository<Participant, Long> {
    
    List<Participant> findByUserId(Long userId);
    
    List<Participant> findByConversationId(Long conversationId);
    
    Optional<Participant> findByUserIdAndConversationId(Long userId, Long conversationId);
    
    @Query("SELECT p FROM Participant p " +
           "WHERE p.conversation.id = :conversationId " +
           "AND p.user.id != :userId")
    List<Participant> findOtherParticipants(@Param("conversationId") Long conversationId, @Param("userId") Long userId);
}
